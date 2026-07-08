import Foundation
import Supabase

@MainActor
final class ProjectRepository {
  static let shared = ProjectRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func fetchProjects() async throws -> [Project] {
    guard let userId = client.auth.currentUser?.id else { return [] }
    let rows: [ProjectRowDTO] = try await client
      .from("projects")
      .select("id, nome, cor")
      .eq("user_id", value: userId)
      .order("nome", ascending: true)
      .execute()
      .value
    return rows.map(Project.init(row:))
  }

  func fetchHomeProjects() async throws -> [HomeProject] {
    guard let userId = client.auth.currentUser?.id else { return [] }
    let rows: [ProjectRowDTO] = try await client
      .from("projects")
      .select("id, nome, cor, icone")
      .eq("user_id", value: userId)
      .order("nome", ascending: true)
      .execute()
      .value

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

  struct ProjectDetails {
    let name: String?
    let colorHex: String?
    let iconName: String?
  }

  func fetchProjectDetails(_ id: String) async throws -> ProjectDetails? {
    let row: ProjectRowDTO = try await client
      .from("projects")
      .select("id, nome, cor, icone")
      .eq("id", value: id)
      .single()
      .execute()
      .value
    return ProjectDetails(name: row.nome, colorHex: row.cor, iconName: row.icone)
  }

  func fetchProjectsWithTaskStats() async throws -> [ProjectTaskStats] {
    struct TaskDoneRow: Decodable { let concluida: Bool? }
    struct Row: Decodable {
      let id: String
      let nome: String?
      let cor: String?
      let icone: String?
      let tasks: [TaskDoneRow]?
    }

    let rows: [Row]
    do {
      rows = try await client
        .from("projects")
        .select("id, nome, cor, icone, tasks(concluida)")
        .order("nome", ascending: true)
        .execute()
        .value
    } catch {
      rows = try await client
        .from("projects")
        .select("id, nome, cor, tasks(concluida)")
        .order("nome", ascending: true)
        .execute()
        .value
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
}
