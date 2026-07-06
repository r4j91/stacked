import Foundation
import Supabase

@MainActor
final class SavedFilterRepository {
  static let shared = SavedFilterRepository()

  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func fetchSavedFilters() async throws -> [SavedFilter] {
    let rows: [SavedFilterRowDTO] = try await client
      .from("saved_filters")
      .select("id, name, color, criteria, sort_order")
      .order("sort_order", ascending: true)
      .order("created_at", ascending: true)
      .execute()
      .value
    return rows.map { $0.toModel() }
  }

  func fetchSavedFiltersWithCounts(todayStr: String, weekStr: String) async throws -> [SavedFilterWithCount] {
    let filters = try await fetchSavedFilters()
    var result: [SavedFilterWithCount] = []
    for filter in filters {
      let split = try await TaskRepository.shared.fetchFilterResults(
        filter.criteria,
        todayStr: todayStr,
        weekStr: weekStr
      )
      result.append(SavedFilterWithCount(filter: filter, pendingCount: split.pending.count))
    }
    return result
  }

  func createSavedFilter(name: String, colorHex: String?, criteria: FilterCriteria) async throws -> SavedFilter {
    guard let userId = client.auth.currentUser?.id else {
      throw NSError(domain: "Stacked", code: 401, userInfo: [NSLocalizedDescriptionKey: "Não autenticado"])
    }
    struct Payload: Encodable {
      let user_id: UUID
      let name: String
      let color: String?
      let criteria: FilterCriteria
    }
    let row: SavedFilterRowDTO = try await client.from("saved_filters")
      .insert(Payload(user_id: userId, name: name.trimmingCharacters(in: .whitespacesAndNewlines), color: colorHex, criteria: criteria))
      .select("id, name, color, criteria, sort_order")
      .single()
      .execute()
      .value
    return row.toModel()
  }

  func updateSavedFilter(id: String, name: String, colorHex: String?, criteria: FilterCriteria) async throws -> SavedFilter {
    struct Payload: Encodable {
      let name: String
      let color: String?
      let criteria: FilterCriteria
    }
    let row: SavedFilterRowDTO = try await client.from("saved_filters")
      .update(Payload(name: name.trimmingCharacters(in: .whitespacesAndNewlines), color: colorHex, criteria: criteria))
      .eq("id", value: id)
      .select("id, name, color, criteria, sort_order")
      .single()
      .execute()
      .value
    return row.toModel()
  }

  func deleteSavedFilter(id: String) async throws {
    try await client.from("saved_filters").delete().eq("id", value: id).execute()
  }
}

private struct SavedFilterRowDTO: Decodable {
  let id: String
  let name: String
  let color: String?
  let criteria: FilterCriteria?
  let sort_order: Int

  func toModel() -> SavedFilter {
    SavedFilter(
      id: id,
      name: name,
      colorHex: color,
      criteria: criteria ?? .empty,
      sortOrder: sort_order
    )
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) { id = s }
    else { id = try c.decode(UUID.self, forKey: .id).uuidString }
    name = try c.decode(String.self, forKey: .name)
    color = try c.decodeIfPresent(String.self, forKey: .color)
    criteria = try c.decodeIfPresent(FilterCriteria.self, forKey: .criteria)
    sort_order = try c.decodeIfPresent(Int.self, forKey: .sort_order) ?? 0
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, color, criteria, sort_order
  }
}
