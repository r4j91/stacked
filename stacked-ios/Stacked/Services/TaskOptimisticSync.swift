import Foundation

/// NET_FASEC_ETAPA2 — fila de sync otimista (insert/update) com retry e verify-by-id.
@MainActor
enum TaskOptimisticSync {
  private static let retryDelays: [UInt64] = [1_000_000_000, 3_000_000_000] // 1s, 3s
  private static let requestTimeoutSeconds: TimeInterval = 15
  private static var pendingIds: Set<String> = []
  private static var failedIds: Set<String> = []
  private static var inFlight: Set<String> = []

  static func isPending(_ id: String) -> Bool { pendingIds.contains(id) }
  static func isFailed(_ id: String) -> Bool { failedIds.contains(id) }

  static func markPending(_ id: String) {
    pendingIds.insert(id)
    failedIds.remove(id)
  }

  static func markSynced(_ id: String) {
    pendingIds.remove(id)
    failedIds.remove(id)
  }

  static func markFailed(_ id: String) {
    pendingIds.remove(id)
    failedIds.insert(id)
  }

  /// Valida se o Postgres aceita UUID gerado no cliente (insert + delete).
  /// Retorna nil se a rede falhou (indeterminado) — não bloqueia o save.
  static func validateClientGeneratedId() async -> Bool? {
    guard let userId = SupabaseService.client.auth.currentUser?.id else { return false }
    let probeId = UUID().uuidString.lowercased()
    do {
      try await NetLog.timed("tasks.probe_client_id", step: .insertTask) {
        try await withTimeout(requestTimeoutSeconds) {
          try await TaskRepository.shared.insertTaskWithClientId(
            id: probeId,
            input: .init(
              title: "__net_facec_probe__",
              description: nil,
              priority: nil,
              projectId: nil,
              sectionId: nil,
              dueDateISO: nil,
              time: nil,
              labelIds: []
            ),
            userId: userId
          )
        }
      }
      try? await TaskRepository.shared.deleteTask(id: probeId)
      NetLog.record(
        operation: "tasks.probe_client_id",
        step: .insertTask,
        durationMs: 0,
        result: .success,
        detail: "client UUID accepted"
      )
      return true
    } catch {
      let kind = NetLog.classify(error)
      NetLog.record(
        operation: "tasks.probe_client_id",
        step: .insertTask,
        durationMs: 0,
        result: kind,
        detail: "CLIENT_UUID_RESULT: \(error.localizedDescription)"
      )
      // Rede/timeout — indeterminado; NÃO tratar como rejeição de schema.
      if kind == .noNetwork || kind == .timeout || kind == .auth {
        return nil
      }
      return false
    }
  }

  private static var clientUuidAccepted: Bool?

  static func enqueueCreate(
    id: String,
    input: TaskRepository.CreateTaskInput,
    projectName: String
  ) {
    markPending(id)
    _Concurrency.Task {
      // NET_FASEC_ETAPA2 — validar id explícito uma vez por sessão quando online.
      if clientUuidAccepted != true {
        let result = await validateClientGeneratedId()
        if result == true {
          clientUuidAccepted = true
        } else if result == false {
          clientUuidAccepted = false
          markFailed(id)
          SyncFeedback.shared.showMessage(
            "Não foi possível sincronizar — servidor rejeitou UUID do cliente. Parar e reportar (schema).",
            taskId: id
          )
          return
        }
        // nil = rede indeterminada → tenta upsert real
      }
      await syncCreate(id: id, input: input, projectName: projectName, isRetry: false)
    }
  }

  static func retryCreate(id: String, input: TaskRepository.CreateTaskInput, projectName: String) {
    SyncFeedback.shared.dismiss()
    markPending(id)
    _Concurrency.Task {
      await syncCreate(id: id, input: input, projectName: projectName, isRetry: true)
    }
  }

  private static func syncCreate(
    id: String,
    input: TaskRepository.CreateTaskInput,
    projectName: String,
    isRetry: Bool
  ) async {
    guard !inFlight.contains(id) else { return }
    inFlight.insert(id)
    defer { inFlight.remove(id) }

    let flowStart = Date()
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      let err = SyncError.falhaAuth
      handleCreateFailure(id: id, input: input, projectName: projectName, error: err)
      return
    }

    var lastError: Error?
    let attempts = 1 + retryDelays.count
    for attempt in 0..<attempts {
      if attempt > 0 {
        let delay = retryDelays[attempt - 1]
        try? await _Concurrency.Task.sleep(nanoseconds: delay)
      }
      do {
        try await withTimeout(requestTimeoutSeconds) {
          try await TaskRepository.shared.upsertTaskWithClientId(
            id: id,
            input: input,
            userId: userId
          )
        }
        // Labels fora do critical path — falha própria.
        if !input.labelIds.isEmpty {
          await syncLabels(taskId: id, labelIds: input.labelIds)
        }
        // Notif: só esta tarefa.
        if let dueISO = input.dueDateISO,
           let due = TaskMapper.parseDueDate(dueISO),
           let time = input.time,
           !time.isEmpty {
          let notifStart = Date()
          _ = await NotificationService.shared.scheduleTaskNotification(
            id: id,
            title: input.title,
            dueDate: due,
            time: time
          )
          NetLog.record(
            operation: "notif.schedule_single",
            step: .notif,
            durationMs: Int(Date().timeIntervalSince(notifStart) * 1000),
            result: .success
          )
        }
        // Calendário em background, nunca falha o save.
        _Concurrency.Task {
          let calStart = Date()
          await TaskCalendarSync.syncTaskId(id)
          NetLog.record(
            operation: "calendar.syncTaskId",
            step: .calendar,
            durationMs: Int(Date().timeIntervalSince(calStart) * 1000),
            result: .success
          )
        }
        markSynced(id)
        NetLog.record(
          operation: isRetry ? "quickadd.create.retry_ok" : "quickadd.create.ok",
          step: .flowSave,
          durationMs: Int(Date().timeIntervalSince(flowStart) * 1000),
          result: .success,
          detail: "id=\(id)"
        )
        return
      } catch {
        lastError = error
        let kind = NetLog.classify(error)
        if kind == .timeout {
          if await TaskRepository.shared.taskExists(id: id) {
            markSynced(id)
            if !input.labelIds.isEmpty {
              await syncLabels(taskId: id, labelIds: input.labelIds)
            }
            NetLog.record(
              operation: "quickadd.create.timeout_verified",
              step: .selectVerify,
              durationMs: Int(Date().timeIntervalSince(flowStart) * 1000),
              result: .success,
              detail: "id=\(id)"
            )
            return
          }
        }
      }
    }

    let syncErr = SyncError.from(lastError ?? NSError(domain: "Stacked", code: -1))
    if case .timeoutVerificado = syncErr {
      markSynced(id)
      return
    }
    handleCreateFailure(id: id, input: input, projectName: projectName, error: syncErr)
    NetLog.record(
      operation: "quickadd.create.failed",
      step: .flowSave,
      durationMs: Int(Date().timeIntervalSince(flowStart) * 1000),
      result: .server,
      detail: lastError?.localizedDescription
    )
  }

  private static func handleCreateFailure(
    id: String,
    input: TaskRepository.CreateTaskInput,
    projectName: String,
    error: SyncError
  ) {
    markFailed(id)
    SyncFeedback.shared.show(error, taskId: id) {
      retryCreate(id: id, input: input, projectName: projectName)
    }
  }

  private static func syncLabels(taskId: String, labelIds: [String]) async {
    let attempts = 1 + retryDelays.count
    for attempt in 0..<attempts {
      if attempt > 0 {
        try? await _Concurrency.Task.sleep(nanoseconds: retryDelays[attempt - 1])
      }
      do {
        try await NetLog.timed("task_labels.set", step: .insertLabels) {
          try await withTimeout(requestTimeoutSeconds) {
            try await LabelRepository.shared.setTaskLabels(taskId: taskId, labelIds: labelIds)
          }
        }
        return
      } catch {
        if attempt == attempts - 1 {
          NetLog.record(
            operation: "task_labels.set.failed",
            step: .insertLabels,
            durationMs: 0,
            result: NetLog.classify(error),
            detail: error.localizedDescription
          )
          // Labels não falham o save da tarefa — toast discreto opcional.
          SyncFeedback.shared.show(.falhaServidor(nil), taskId: taskId) {
            _Concurrency.Task { await syncLabels(taskId: taskId, labelIds: labelIds) }
          }
        }
      }
    }
  }

  static func withTimeout<T>(
    _ seconds: TimeInterval,
    operation: @escaping () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await _Concurrency.Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw NSError(
          domain: NSURLErrorDomain,
          code: NSURLErrorTimedOut,
          userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )
      }
      guard let result = try await group.next() else {
        throw NSError(domain: "Stacked", code: -2, userInfo: [NSLocalizedDescriptionKey: "Timeout group empty"])
      }
      group.cancelAll()
      return result
    }
  }
}
