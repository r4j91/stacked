import Foundation
import Supabase

extension Notification.Name {
  static let labelsCatalogDidChange = Notification.Name("labelsCatalogDidChange")
}

@MainActor
final class LabelRepository {
  static let shared = LabelRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  private(set) var cachedLabels: [TaskLabel] = []

  func invalidateCache() {
    cachedLabels = []
    LabelCatalogCache.invalidate()
    NotificationCenter.default.post(name: .labelsCatalogDidChange, object: nil)
  }

  func fetchLabels(force: Bool = false) async throws -> [TaskLabel] {
    if !force, !cachedLabels.isEmpty { return cachedLabels }
    let rows: [LabelRowDTO] = try await client
      .from("labels")
      .select("id, nome, cor, sort_order")
      .order("sort_order", ascending: true)
      .order("nome", ascending: true)
      .execute()
      .value
    let mapped = rows.map {
      TaskLabel(
        id: $0.id,
        name: $0.nome ?? "",
        color: AppColors.parseHex($0.cor),
        sortOrder: $0.sort_order
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
    let lastOrder: Int = {
      let rows: [LabelSortRowDTO] = (try? await client
        .from("labels")
        .select("sort_order")
        .order("sort_order", ascending: false)
        .limit(1)
        .execute()
        .value) ?? []
      return (rows.first?.sort_order ?? -1) + 1
    }()
    struct Payload: Encodable {
      let nome: String
      let cor: String
      let user_id: UUID
      let sort_order: Int
    }
    try await client.from("labels").insert(
      Payload(nome: name, cor: colorHex, user_id: userId, sort_order: lastOrder)
    ).execute()
    invalidateCache()
  }

  func updateLabel(id: String, name: String, colorHex: String) async throws {
    try await client.from("labels").update(["nome": name, "cor": colorHex]).eq("id", value: id).execute()
    invalidateCache()
  }

  func deleteLabel(id: String) async throws {
    try await client.from("labels").delete().eq("id", value: id).execute()
    invalidateCache()
  }

  func reorderLabels(ids: [String]) async throws {
    for (index, id) in ids.enumerated() {
      try await client.from("labels").update(["sort_order": index]).eq("id", value: id).execute()
    }
    invalidateCache()
  }
}

struct LabelSortRowDTO: Decodable {
  let sort_order: Int

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    sort_order = try c.decodeIfPresent(Int.self, forKey: .sort_order) ?? 0
  }

  private enum CodingKeys: String, CodingKey { case sort_order }
}

struct LabelRowDTO: Decodable {
  let id: String
  let nome: String?
  let cor: String?
  let sort_order: Int

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) { id = s }
    else { id = try c.decode(UUID.self, forKey: .id).uuidString }
    nome = try c.decodeIfPresent(String.self, forKey: .nome)
    cor = try c.decodeIfPresent(String.self, forKey: .cor)
    sort_order = try c.decodeIfPresent(Int.self, forKey: .sort_order) ?? 0
  }

  private enum CodingKeys: String, CodingKey { case id, nome, cor, sort_order }
}
