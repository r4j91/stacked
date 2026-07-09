import Foundation
import Supabase

// Paridade lib/services/task_detail_persistence.dart
@MainActor
enum TaskDetailPersistence {
  private static var client: SupabaseClient { SupabaseService.client }

  static func autosaveTitle(taskId: String, title: String) async {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    try? await client.from("tasks").update(["titulo": trimmed]).eq("id", value: taskId).execute()
  }

  static func autosaveDescription(taskId: String, description: String) async {
    let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      try? await client.from("tasks").update(["descricao": Optional<String>.none]).eq("id", value: taskId).execute()
    } else {
      try? await client.from("tasks").update(["descricao": trimmed]).eq("id", value: taskId).execute()
    }
  }

  static func autosavePriority(taskId: String, priority: Priority?) async {
    if let priority {
      try? await client.from("tasks").update(["prioridade": priority.rawValue]).eq("id", value: taskId).execute()
    } else {
      try? await client.from("tasks").update(["prioridade": Optional<String>.none]).eq("id", value: taskId).execute()
    }
  }

  static func autosaveDueDate(taskId: String, isoDate: String?) async {
    if let isoDate {
      try? await client.from("tasks").update(["data_vencimento": isoDate]).eq("id", value: taskId).execute()
    } else {
      try? await client.from("tasks").update(["data_vencimento": Optional<String>.none]).eq("id", value: taskId).execute()
    }
  }

  static func autosaveTime(taskId: String, time: String?) async {
    if let time, !time.isEmpty {
      try? await client.from("tasks").update(["hora": time]).eq("id", value: taskId).execute()
    } else {
      try? await client.from("tasks").update(["hora": Optional<String>.none]).eq("id", value: taskId).execute()
    }
  }

  static func autosaveWhatsappRoutine(taskId: String, enabled: Bool) async {
    try? await client.from("tasks").update(["whatsapp_rotina": enabled]).eq("id", value: taskId).execute()
  }

  static func autosaveProject(taskId: String, projectId: String?) async {
    if let projectId {
      try? await client.from("tasks").update([
        "project_id": projectId,
        "section_id": Optional<String>.none,
      ]).eq("id", value: taskId).execute()
    } else {
      try? await client.from("tasks").update([
        "project_id": Optional<String>.none,
        "section_id": Optional<String>.none,
      ]).eq("id", value: taskId).execute()
    }
  }
}
