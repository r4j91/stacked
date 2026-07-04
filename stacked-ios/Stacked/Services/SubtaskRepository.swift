import Foundation
import Supabase

@MainActor
final class SubtaskRepository {
  static let shared = SubtaskRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func toggleDone(id: String, done: Bool) async throws {
    try await client
      .from("subtasks")
      .update(["concluida": done])
      .eq("id", value: id)
      .execute()
  }

  func createSubtask(taskId: String, title: String, order: Int) async throws -> String {
    struct InsertPayload: Encodable {
      let task_id: String
      let titulo: String
      let ordem: Int
      let concluida: Bool
    }
    struct Inserted: Decodable { let id: String }

    let row: Inserted = try await client
      .from("subtasks")
      .insert(InsertPayload(task_id: taskId, titulo: title, ordem: order, concluida: false))
      .select("id")
      .single()
      .execute()
      .value
    return row.id
  }

  /// Paridade SubtaskRepository.createSubtasksBatch — gerador de parcelas.
  func createSubtasksBatch(_ rows: [InstallmentSubtaskInsert]) async throws {
    guard !rows.isEmpty else { return }
    try await client.from("subtasks").insert(rows).execute()
  }

  struct InstallmentSubtaskInsert: Encodable {
    let task_id: String
    let titulo: String
    let data_vencimento: String
    let valor: Double?
    let concluida: Bool
    let ordem: Int
  }

  func updateTitle(id: String, title: String) async throws {
    try await client
      .from("subtasks")
      .update(["titulo": title])
      .eq("id", value: id)
      .execute()
  }

  func deleteSubtask(id: String) async throws {
    try await client.from("subtasks").delete().eq("id", value: id).execute()
  }

  func updateMetadata(
    id: String,
    priority: Priority?,
    dueDateISO: String?,
    labelIds: [String]
  ) async throws {
    struct Payload: Encodable {
      let prioridade: String?
      let data_vencimento: String?
      let label_ids: [String]?
    }
    try await client
      .from("subtasks")
      .update(Payload(
        prioridade: priority?.rawValue,
        data_vencimento: dueDateISO,
        label_ids: labelIds.isEmpty ? nil : labelIds
      ))
      .eq("id", value: id)
      .execute()
  }
}
