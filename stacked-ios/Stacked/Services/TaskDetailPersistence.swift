import Foundation
import Supabase

// Paridade lib/services/task_detail_persistence.dart
@MainActor
enum TaskDetailPersistence {
  private static var client: SupabaseClient { SupabaseService.client }
  private static let retryDelays: [UInt64] = [1_000_000_000, 3_000_000_000]

  // NET_FASEC_ETAPA3 — deixa de engolir erros com try?; NetLog + toast + retry.
  private static func persist(
    operation: String,
    taskId: String,
    work: @escaping () async throws -> Void
  ) async {
    let attempts = 1 + retryDelays.count
    var lastError: Error?
    for attempt in 0..<attempts {
      if attempt > 0 {
        try? await _Concurrency.Task.sleep(nanoseconds: retryDelays[attempt - 1])
      }
      do {
        try await NetLog.timed(operation, step: .updateTask) {
          try await TaskOptimisticSync.withTimeout(15, operation: work)
        }
        return
      } catch {
        lastError = error
        if NetLog.classify(error) == .timeout {
          // Update: não dá para verify facilmente o conteúdo; retry cobre.
        }
      }
    }
    if let lastError {
      let syncErr = SyncError.from(lastError)
      SyncFeedback.shared.show(syncErr, taskId: taskId) {
        _Concurrency.Task { await persist(operation: operation, taskId: taskId, work: work) }
      }
    }
  }

  static func autosaveTitle(taskId: String, title: String) async {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    // NET_FASEC_ETAPA3 — try? removido.
    // try? await client.from("tasks").update(["titulo": trimmed]).eq("id", value: taskId).execute()
    await persist(operation: "tasks.update.titulo", taskId: taskId) {
      try await client.from("tasks").update(["titulo": trimmed]).eq("id", value: taskId).execute()
    }
  }

  static func autosaveDescription(taskId: String, description: String) async {
    let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
    await persist(operation: "tasks.update.descricao", taskId: taskId) {
      if trimmed.isEmpty {
        try await client.from("tasks").update(["descricao": Optional<String>.none]).eq("id", value: taskId).execute()
      } else {
        try await client.from("tasks").update(["descricao": trimmed]).eq("id", value: taskId).execute()
      }
    }
  }

  static func autosavePriority(taskId: String, priority: Priority?) async {
    await persist(operation: "tasks.update.prioridade", taskId: taskId) {
      if let priority {
        try await client.from("tasks").update(["prioridade": priority.rawValue]).eq("id", value: taskId).execute()
      } else {
        try await client.from("tasks").update(["prioridade": Optional<String>.none]).eq("id", value: taskId).execute()
      }
    }
  }

  static func autosaveDueDate(taskId: String, isoDate: String?) async {
    await persist(operation: "tasks.update.data_vencimento", taskId: taskId) {
      if let isoDate {
        try await client.from("tasks").update(["data_vencimento": isoDate]).eq("id", value: taskId).execute()
      } else {
        try await client.from("tasks").update(["data_vencimento": Optional<String>.none]).eq("id", value: taskId).execute()
      }
    }
  }

  static func autosaveTime(taskId: String, time: String?) async {
    await persist(operation: "tasks.update.hora", taskId: taskId) {
      if let time, !time.isEmpty {
        try await client.from("tasks").update(["hora": time]).eq("id", value: taskId).execute()
      } else {
        try await client.from("tasks").update(["hora": Optional<String>.none]).eq("id", value: taskId).execute()
      }
    }
  }

  /// NET_FASEC_ETAPA3 — data+hora em 1 PATCH.
  static func autosaveDueDateAndTime(taskId: String, isoDate: String?, time: String?) async {
    struct Payload: Encodable {
      let data_vencimento: String?
      let hora: String?

      enum CodingKeys: String, CodingKey { case data_vencimento, hora }

      func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let data_vencimento {
          try c.encode(data_vencimento, forKey: .data_vencimento)
        } else {
          try c.encodeNil(forKey: .data_vencimento)
        }
        if let hora, !hora.isEmpty {
          try c.encode(hora, forKey: .hora)
        } else {
          try c.encodeNil(forKey: .hora)
        }
      }
    }
    await persist(operation: "tasks.update.due_and_time", taskId: taskId) {
      try await client.from("tasks").update(
        Payload(data_vencimento: isoDate, hora: time)
      ).eq("id", value: taskId).execute()
    }
  }

  static func autosaveWhatsappRoutine(taskId: String, enabled: Bool) async {
    await persist(operation: "tasks.update.whatsapp", taskId: taskId) {
      try await client.from("tasks").update(["whatsapp_rotina": enabled]).eq("id", value: taskId).execute()
    }
  }

  static func autosaveProject(taskId: String, projectId: String?) async {
    await persist(operation: "tasks.update.project", taskId: taskId) {
      if let projectId {
        try await client.from("tasks").update([
          "project_id": projectId,
          "section_id": Optional<String>.none,
        ]).eq("id", value: taskId).execute()
      } else {
        try await client.from("tasks").update([
          "project_id": Optional<String>.none,
          "section_id": Optional<String>.none,
        ]).eq("id", value: taskId).execute()
      }
    }
  }
}
