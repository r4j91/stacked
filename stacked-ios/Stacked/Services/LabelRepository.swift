import Foundation
import Supabase

@MainActor
final class LabelRepository {
  static let shared = LabelRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  private(set) var cachedLabels: [TaskLabel] = []

  func fetchLabels(force: Bool = false) async throws -> [TaskLabel] {
    if !force, !cachedLabels.isEmpty { return cachedLabels }
    let rows: [LabelRowDTO] = try await client
      .from("labels")
      .select("id, nome, cor")
      .order("nome", ascending: true)
      .execute()
      .value
    let mapped = rows.map {
      TaskLabel(
        id: $0.id,
        name: $0.nome ?? "",
        color: AppColors.parseHex($0.cor)
      )
    }
    cachedLabels = mapped
    return mapped
  }

  func setTaskLabels(taskId: String, labelIds: [String]) async throws {
    try await client.from("task_labels").delete().eq("task_id", value: taskId).execute()
    guard !labelIds.isEmpty else { return }
    let payload = labelIds.map { ["task_id": taskId, "label_id": $0] }
    try await client.from("task_labels").insert(payload).execute()
  }

  func createLabel(name: String, colorHex: String) async throws {
    guard let userId = client.auth.currentUser?.id else { return }
    struct Payload: Encodable { let nome: String; let cor: String; let user_id: UUID }
    try await client.from("labels").insert(
      Payload(nome: name, cor: colorHex, user_id: userId)
    ).execute()
  }

  func updateLabel(id: String, name: String, colorHex: String) async throws {
    try await client.from("labels").update(["nome": name, "cor": colorHex]).eq("id", value: id).execute()
  }

  func deleteLabel(id: String) async throws {
    try await client.from("labels").delete().eq("id", value: id).execute()
  }
}

struct LabelRowDTO: Decodable {
  let id: String
  let nome: String?
  let cor: String?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) { id = s }
    else { id = try c.decode(UUID.self, forKey: .id).uuidString }
    nome = try c.decodeIfPresent(String.self, forKey: .nome)
    cor = try c.decodeIfPresent(String.self, forKey: .cor)
  }

  private enum CodingKeys: String, CodingKey { case id, nome, cor }
}
