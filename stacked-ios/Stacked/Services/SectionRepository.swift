import Foundation
import Supabase

@MainActor
final class SectionRepository {
  static let shared = SectionRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func fetchSections(projectId: String) async throws -> [ProjectSection] {
    let rows: [SectionRowDTO] = try await client
      .from("sections")
      .select("id, project_id, name, order")
      .eq("project_id", value: projectId)
      .order("order", ascending: true)
      .execute()
      .value
    return rows.map(\.model)
  }

  func createSection(projectId: String, name: String) async throws {
    struct Payload: Encodable {
      let project_id: String
      let name: String
      let order: Int
    }
    try await client.from("sections").insert(
      Payload(project_id: projectId, name: name, order: 0)
    ).execute()
  }

  func renameSection(id: String, name: String) async throws {
    try await client.from("sections").update(["name": name]).eq("id", value: id).execute()
  }

  func deleteSection(id: String) async throws {
    try await client.from("sections").delete().eq("id", value: id).execute()
  }
}
