import Foundation
import Supabase

struct TaskComment: Identifiable, Equatable {
  let id: String
  let content: String
  let createdAt: Date
}

@MainActor
final class CommentRepository {
  static let shared = CommentRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func fetchComments(taskId: String) async throws -> [TaskComment] {
    struct Row: Decodable {
      let id: String
      let conteudo: String?
      let created_at: String?
    }
    let rows: [Row] = try await client
      .from("task_comments")
      .select("id, conteudo, created_at")
      .eq("task_id", value: taskId)
      .order("created_at", ascending: true)
      .execute()
      .value
    return rows.compactMap { row in
      guard let text = row.conteudo, !text.isEmpty else { return nil }
      let date = ISO8601DateFormatter().date(from: row.created_at ?? "") ?? Date()
      return TaskComment(id: row.id, content: text, createdAt: date)
    }
  }

  func sendComment(taskId: String, text: String) async throws {
    guard let userId = client.auth.currentUser?.id else { return }
    struct Payload: Encodable {
      let task_id: String
      let conteudo: String
      let user_id: UUID
    }
    try await client.from("task_comments").insert(
      Payload(task_id: taskId, conteudo: text, user_id: userId)
    ).execute()
  }
}
