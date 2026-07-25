import Foundation
import Supabase
import UniformTypeIdentifiers

@MainActor
final class AttachmentRepository {
  static let shared = AttachmentRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  private struct Row: Decodable {
    let id: String
    let task_id: String
    let subtask_id: String?
    let file_name: String
    let mime_type: String
    let size_bytes: Int64
    let storage_path: String
    let created_at: String
  }

  private struct InsertPayload: Encodable {
    let id: String
    let user_id: String
    let task_id: String
    let subtask_id: String?
    let storage_path: String
    let file_name: String
    let mime_type: String
    let size_bytes: Int64
  }

  func listForTask(taskId: String) async throws -> [TaskAttachment] {
    let rows: [Row] = try await client
      .from("task_attachments")
      .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
      .eq("task_id", value: taskId)
      .is("subtask_id", value: nil)
      .order("created_at", ascending: true)
      .execute()
      .value
    return rows.map(mapRow)
  }

  func listForSubtask(subtaskId: String) async throws -> [TaskAttachment] {
    let rows: [Row] = try await client
      .from("task_attachments")
      .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
      .eq("subtask_id", value: subtaskId)
      .order("created_at", ascending: true)
      .execute()
      .value
    return rows.map(mapRow)
  }

  func upload(
    taskId: String,
    subtaskId: String? = nil,
    data: Data,
    fileName: String,
    mimeType: String
  ) async throws -> TaskAttachment {
    guard let userId = client.auth.currentUser?.id.uuidString else {
      throw AttachmentError.notAuthenticated
    }
    guard AttachmentLimits.isAllowedMime(mimeType) else {
      throw AttachmentError.unsupportedType
    }
    guard data.count > 0, Int64(data.count) <= AttachmentLimits.maxBytes else {
      throw AttachmentError.tooLarge
    }

    let id = UUID().uuidString.lowercased()
    let safeName = sanitize(fileName)
    let path = "\(userId.lowercased())/\(id)/\(safeName)"

    try await client.storage
      .from("attachments")
      .upload(path, data: data, options: FileOptions(contentType: mimeType, upsert: false))

    do {
      let rows: [Row] = try await client
        .from("task_attachments")
        .insert(
          InsertPayload(
            id: id,
            user_id: userId.lowercased(),
            task_id: taskId,
            subtask_id: subtaskId,
            storage_path: path,
            file_name: safeName,
            mime_type: mimeType,
            size_bytes: Int64(data.count)
          )
        )
        .select("id, task_id, subtask_id, file_name, mime_type, size_bytes, storage_path, created_at")
        .execute()
        .value
      guard let row = rows.first else { throw AttachmentError.uploadFailed }
      return mapRow(row)
    } catch {
      _ = try? await client.storage.from("attachments").remove(paths: [path])
      throw error
    }
  }

  func signedURL(for storagePath: String, expiresIn: Int = 3600) async throws -> URL {
    let url = try await client.storage
      .from("attachments")
      .createSignedURL(path: storagePath, expiresIn: expiresIn)
    return url
  }

  func remove(_ attachment: TaskAttachment) async throws {
    try await client.from("task_attachments").delete().eq("id", value: attachment.id).execute()
    _ = try? await client.storage.from("attachments").remove(paths: [attachment.storagePath])
  }

  private func mapRow(_ row: Row) -> TaskAttachment {
    TaskAttachment(
      id: row.id,
      taskId: row.task_id,
      subtaskId: row.subtask_id,
      fileName: row.file_name,
      mimeType: row.mime_type,
      sizeBytes: row.size_bytes,
      storagePath: row.storage_path,
      createdAt: row.created_at
    )
  }

  private func sanitize(_ name: String) -> String {
    let cleaned = name.replacingOccurrences(
      of: #"[^\w.\-+() ]+"#,
      with: "_",
      options: .regularExpression
    )
    let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "arquivo" }
    return String(trimmed.prefix(180))
  }
}

enum AttachmentError: LocalizedError {
  case notAuthenticated
  case unsupportedType
  case tooLarge
  case uploadFailed

  var errorDescription: String? {
    switch self {
    case .notAuthenticated: "Não autenticado"
    case .unsupportedType: "Só imagens ou PDF"
    case .tooLarge: "Arquivo deve ter no máximo 20 MB"
    case .uploadFailed: "Falha no upload"
    }
  }
}
