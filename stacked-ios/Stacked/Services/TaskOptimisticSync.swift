import Foundation

/// NET_FASEC_ETAPA2 — fila de sync otimista (insert/update) com retry e verify-by-id.
@MainActor
enum TaskOptimisticSync {
  private static let retryDelays: [UInt64] = [1_000_000_000, 3_000_000_000] // 1s, 3s
  private static let requestTimeoutSeconds: TimeInterval = 20
  private static var pendingIds: Set<String> = []
  private static var failedIds: Set<String> = []
  private static var inFlight: Set<String> = []
  private static var clientUuidAccepted: Bool?

  static func isPending(_ id: String) -> Bool { pendingIds.contains(id) || inFlight.contains(id) }
  static func isFailed(_ id: String) -> Bool { failedIds.contains(id) }

  static func markPending(_ id: String) {
    pendingIds.insert(id)
    failedIds.remove(id)
  }

  static func markSynced(_ id: String) {
    pendingIds.remove(id)
    failedIds.remove(id)
    SyncFeedback.shared.clearSuccess(for: id)
  }

  static func markFailed(_ id: String) {
    pendingIds.remove(id)
    failedIds.insert(id)
  }

  /// Aguarda create otimista concluir antes de PATCH/labels no Detail.
  static func waitUntilReady(taskId: String, timeoutSeconds: TimeInterval = 12) async {
    guard isPending(taskId) else { return }
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while Date() < deadline {
      if !isPending(taskId) { return }
      try? await _Concurrency.Task.sleep(for: .milliseconds(120))
    }
  }

  /// Valida UUID client via insert+delete — só NetLog debug (não no critical path do save).
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
      if kind == .noNetwork || kind == .timeout || kind == .auth {
        return nil
      }
      return false
    }
  }

  static func enqueueCreate(
    id: String,
    input: TaskRepository.CreateTaskInput,
    projectName: String
  ) {
    markPending(id)
    _Concurrency.Task {
      // NET_FASEC_ETAPA2 fix: não fazer probe no critical path — o upsert real valida o UUID.
      // Probe fica só no botão NetLog (evita toast/rede extra no Quick Add).
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
    let userId: UUID
    if let uid = SupabaseService.client.auth.currentUser?.id {
      userId = uid
    } else {
      _ = try? await SupabaseService.client.auth.refreshSession()
      guard let uid = SupabaseService.client.auth.currentUser?.id else {
        handleCreateFailure(id: id, input: input, projectName: projectName, error: .falhaAuth)
        return
      }
      userId = uid
    }

    var lastError: Error?
    let attempts = 1 + retryDelays.count
    for attempt in 0..<attempts {
      if attempt > 0 {
        try? await _Concurrency.Task.sleep(nanoseconds: retryDelays[attempt - 1])
      }
      do {
        try await withTimeout(requestTimeoutSeconds) {
          try await TaskRepository.shared.upsertTaskWithClientId(
            id: id,
            input: input,
            userId: userId
          )
        }
        clientUuidAccepted = true
        if !input.labelIds.isEmpty {
          await syncLabels(taskId: id, labelIds: input.labelIds)
        }
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
        // Timeout / cancel / any soft fail: verify by id antes de declarar erro.
        if await TaskRepository.shared.taskExists(id: id) {
          clientUuidAccepted = true
          if !input.labelIds.isEmpty {
            await syncLabels(taskId: id, labelIds: input.labelIds)
          }
          markSynced(id)
          NetLog.record(
            operation: "quickadd.create.verified_ok",
            step: .selectVerify,
            durationMs: Int(Date().timeIntervalSince(flowStart) * 1000),
            result: .success,
            detail: "id=\(id) after \(NetLog.classify(error).rawValue)"
          )
          return
        }
      }
    }

    // Última verificação pós-retries.
    if await TaskRepository.shared.taskExists(id: id) {
      clientUuidAccepted = true
      markSynced(id)
      return
    }

    let syncErr = SyncError.from(lastError ?? NSError(domain: "Stacked", code: -1))
    if case .timeoutVerificado = syncErr {
      markSynced(id)
      return
    }
    if case .cancelado = syncErr {
      // Cancel sem confirmação — não toast; deixa pendente pra retry silencioso depois.
      markPending(id)
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

  /// Labels: retry silencioso — NÃO toast (falha de labels ≠ falha do save da tarefa).
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
          // Silencioso — UI local já tem as etiquetas; próximo edit/reload reconcilia.
        }
      }
    }
  }

  /// Timeout cooperativo: NÃO cancela a request (cancel mid-flight gerava toast falso).
  static func withTimeout<T>(
    _ seconds: TimeInterval,
    operation: @escaping () async throws -> T
  ) async throws -> T {
    // Mantém assinatura usada por persistence/create; o teto real é o da URLSession.
    // Se a operação for lenta, NetLog registra duração — sem abortar escrita no servidor.
    _ = seconds
    return try await operation()
  }
}
