import Foundation
import Supabase

@MainActor
final class ProjectRepository {
  static let shared = ProjectRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  /// Cache em memória — evita retry em todo fetch após detectar schema antigo.
  private var supportsSortOrder: Bool?

  func fetchProjects() async throws -> [Project] {
    guard let userId = client.auth.currentUser?.id else { return [] }
    let rows = try await fetchProjectRows(
      userId: userId,
      selectWithSort: "id, nome, cor, sort_order",
      selectFallback: "id, nome, cor"
    )
    return rows.map(Project.init(row:))
  }

  func fetchHomeProjects() async throws -> [HomeProject] {
    guard let userId = client.auth.currentUser?.id else { return [] }
    let rows = try await fetchProjectRows(
      userId: userId,
      selectWithSort: "id, nome, cor, icone, sort_order",
      selectFallback: "id, nome, cor, icone"
    )

    let projectIds = try await TaskRepository.shared.fetchPendingTaskProjectIds(userId: userId)
    var countMap: [String: Int] = [:]
    for pid in projectIds {
      if let pid { countMap[pid, default: 0] += 1 }
    }

    return rows.map { row in
      HomeProject(
        id: row.id,
        name: row.nome ?? "",
        colorHex: row.cor,
        iconKey: row.icone,
        taskCount: countMap[row.id] ?? 0
      )
    }
  }

  func createProject(name: String, colorHex: String, iconKey: String? = nil) async throws {
    guard let userId = client.auth.currentUser?.id else { return }

    if supportsSortOrder != false {
      let nextOrder = (try? await nextSortOrder(userId: userId)) ?? 0
      struct PayloadWithOrder: Encodable {
        let nome: String
        let cor: String
        let icone: String?
        let user_id: UUID
        let favorito: Bool
        let sort_order: Int
      }
      do {
        try await client.from("projects").insert(
          PayloadWithOrder(
            nome: name,
            cor: colorHex,
            icone: iconKey,
            user_id: userId,
            favorito: false,
            sort_order: nextOrder
          )
        ).execute()
        supportsSortOrder = true
        return
      } catch {
        if !isMissingSortOrder(error) { throw error }
        supportsSortOrder = false
      }
    }

    struct Payload: Encodable {
      let nome: String
      let cor: String
      let icone: String?
      let user_id: UUID
      let favorito: Bool
    }
    try await client.from("projects").insert(
      Payload(nome: name, cor: colorHex, icone: iconKey, user_id: userId, favorito: false)
    ).execute()
  }

  func updateProject(id: String, name: String?, colorHex: String?, iconKey: String?) async throws {
    struct Payload: Encodable {
      let nome: String?
      let cor: String?
      let icone: String?
    }
    try await client.from("projects").update(
      Payload(nome: name, cor: colorHex, icone: iconKey)
    ).eq("id", value: id).execute()
  }

  func deleteProject(id: String) async throws {
    try await client.from("projects").delete().eq("id", value: id).execute()
  }

  func reorderProjects(ids: [String]) async throws {
    for (index, id) in ids.enumerated() {
      do {
        try await client.from("projects").update(["sort_order": index]).eq("id", value: id).execute()
        supportsSortOrder = true
      } catch {
        if isMissingSortOrder(error) {
          supportsSortOrder = false
          throw error
        }
        throw error
      }
    }
  }

  struct ProjectDetails {
    let name: String?
    let colorHex: String?
    let iconName: String?
  }

  func fetchProjectDetails(_ id: String) async throws -> ProjectDetails? {
    do {
      let row: ProjectRowDTO = try await client
        .from("projects")
        .select("id, nome, cor, icone, sort_order")
        .eq("id", value: id)
        .single()
        .execute()
        .value
      return ProjectDetails(name: row.nome, colorHex: row.cor, iconName: row.icone)
    } catch {
      if !isMissingSortOrder(error) { throw error }
      supportsSortOrder = false
      let row: ProjectRowDTO = try await client
        .from("projects")
        .select("id, nome, cor, icone")
        .eq("id", value: id)
        .single()
        .execute()
        .value
      return ProjectDetails(name: row.nome, colorHex: row.cor, iconName: row.icone)
    }
  }

  func fetchProjectsWithTaskStats() async throws -> [ProjectTaskStats] {
    struct TaskDoneRow: Decodable { let concluida: Bool? }
    struct Row: Decodable {
      let id: String
      let nome: String?
      let cor: String?
      let icone: String?
      let tasks: [TaskDoneRow]?

      init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) { id = s }
        else { id = try c.decode(UUID.self, forKey: .id).uuidString }
        nome = try c.decodeIfPresent(String.self, forKey: .nome)
        cor = try c.decodeIfPresent(String.self, forKey: .cor)
        icone = try c.decodeIfPresent(String.self, forKey: .icone)
        tasks = try c.decodeIfPresent([TaskDoneRow].self, forKey: .tasks)
      }

      private enum CodingKeys: String, CodingKey { case id, nome, cor, icone, tasks }
    }

    func fetchByName(select: String) async throws -> [Row] {
      try await client
        .from("projects")
        .select(select)
        .order("nome", ascending: true)
        .execute()
        .value
    }

    func fetchBySort(select: String) async throws -> [Row] {
      try await client
        .from("projects")
        .select(select)
        .order("sort_order", ascending: true)
        .order("nome", ascending: true)
        .execute()
        .value
    }

    let rows: [Row]
    if supportsSortOrder == false {
      do {
        rows = try await fetchByName(select: "id, nome, cor, icone, tasks(concluida)")
      } catch {
        rows = try await fetchByName(select: "id, nome, cor, tasks(concluida)")
      }
    } else {
      do {
        rows = try await fetchBySort(select: "id, nome, cor, icone, tasks(concluida)")
        supportsSortOrder = true
      } catch {
        if isMissingSortOrder(error) {
          supportsSortOrder = false
          do {
            rows = try await fetchByName(select: "id, nome, cor, icone, tasks(concluida)")
          } catch {
            rows = try await fetchByName(select: "id, nome, cor, tasks(concluida)")
          }
        } else if String(describing: error).localizedCaseInsensitiveContains("icone") {
          do {
            rows = try await fetchBySort(select: "id, nome, cor, tasks(concluida)")
            supportsSortOrder = true
          } catch {
            if isMissingSortOrder(error) {
              supportsSortOrder = false
              rows = try await fetchByName(select: "id, nome, cor, tasks(concluida)")
            } else {
              throw error
            }
          }
        } else {
          throw error
        }
      }
    }

    return rows.map { row in
      let tasks = row.tasks ?? []
      return ProjectTaskStats(
        id: row.id,
        name: row.nome ?? "",
        colorHex: row.cor,
        iconKey: row.icone,
        pending: tasks.filter { !($0.concluida ?? false) }.count,
        total: tasks.count
      )
    }
  }

  // MARK: - Private

  private func fetchProjectRows(
    userId: UUID,
    selectWithSort: String,
    selectFallback: String
  ) async throws -> [ProjectRowDTO] {
    if supportsSortOrder == false {
      return try await client
        .from("projects")
        .select(selectFallback)
        .eq("user_id", value: userId)
        .order("nome", ascending: true)
        .execute()
        .value
    }

    do {
      let rows: [ProjectRowDTO] = try await client
        .from("projects")
        .select(selectWithSort)
        .eq("user_id", value: userId)
        .order("sort_order", ascending: true)
        .order("nome", ascending: true)
        .execute()
        .value
      supportsSortOrder = true
      return rows
    } catch {
      guard isMissingSortOrder(error) else { throw error }
      supportsSortOrder = false
      return try await client
        .from("projects")
        .select(selectFallback)
        .eq("user_id", value: userId)
        .order("nome", ascending: true)
        .execute()
        .value
    }
  }

  private func nextSortOrder(userId: UUID) async throws -> Int {
    struct OrderRow: Decodable {
      let sort_order: Int
      init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sort_order = try c.decodeIfPresent(Int.self, forKey: .sort_order) ?? 0
      }
      private enum CodingKeys: String, CodingKey { case sort_order }
    }
    let rows: [OrderRow] = try await client
      .from("projects")
      .select("sort_order")
      .eq("user_id", value: userId)
      .order("sort_order", ascending: false)
      .limit(1)
      .execute()
      .value
    return (rows.first?.sort_order ?? -1) + 1
  }

  private func isMissingSortOrder(_ error: Error) -> Bool {
    let text = String(describing: error).lowercased()
    return text.contains("sort_order") && (text.contains("does not exist") || text.contains("42703"))
  }
}
