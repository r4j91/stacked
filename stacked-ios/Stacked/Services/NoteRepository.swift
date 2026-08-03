import Foundation
import Supabase

extension Notification.Name {
  static let notesDidChange = Notification.Name("notesDidChange")
}

@MainActor
final class NoteRepository {
  static let shared = NoteRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  private func notifyChanged() {
    NotificationCenter.default.post(name: .notesDidChange, object: nil)
  }

  func fetchNotes() async throws -> [Note] {
    let rows: [NoteRowDTO] = try await client
      .from("notes")
      .select("id, title, body, color, pinned, created_at, updated_at")
      .is("archived_at", value: nil)
      .order("pinned", ascending: false)
      .order("updated_at", ascending: false)
      .execute()
      .value
    return rows.map(\.asNote)
  }

  func createNote(title: String?, body: String, color: NoteColor, pinned: Bool = false) async throws -> Note {
    guard let userId = client.auth.currentUser?.id else {
      throw NoteRepositoryError.notAuthenticated
    }
    let payload = NoteInsertDTO(
      user_id: userId,
      title: blankToNil(title),
      body: body,
      color: color.rawValue,
      pinned: pinned
    )
    let rows: [NoteRowDTO] = try await client
      .from("notes")
      .insert(payload)
      .select("id, title, body, color, pinned, created_at, updated_at")
      .execute()
      .value
    guard let note = rows.first?.asNote else {
      throw NoteRepositoryError.insertFailed
    }
    notifyChanged()
    return note
  }

  func updateNote(id: String, title: String?, body: String, color: NoteColor, pinned: Bool) async throws {
    let payload = NoteUpdateDTO(
      title: blankToNil(title),
      body: body,
      color: color.rawValue,
      pinned: pinned
    )
    try await client.from("notes").update(payload).eq("id", value: id).execute()
    notifyChanged()
  }

  func deleteNote(id: String) async throws {
    try await client.from("notes").delete().eq("id", value: id).execute()
    notifyChanged()
  }

  func setPinned(id: String, pinned: Bool) async throws {
    try await client.from("notes").update(["pinned": pinned]).eq("id", value: id).execute()
    notifyChanged()
  }

  private func blankToNil(_ value: String?) -> String? {
    let t = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return t.isEmpty ? nil : t
  }
}

enum NoteRepositoryError: LocalizedError {
  case notAuthenticated
  case insertFailed

  var errorDescription: String? {
    switch self {
    case .notAuthenticated: "Faça login para salvar notas."
    case .insertFailed: "Não foi possível criar a nota."
    }
  }
}

private struct NoteInsertDTO: Encodable {
  let user_id: UUID
  let title: String?
  let body: String
  let color: String
  let pinned: Bool
}

private struct NoteUpdateDTO: Encodable {
  let title: String?
  let body: String
  let color: String
  let pinned: Bool
}

private struct NoteRowDTO: Decodable {
  let id: String
  let title: String?
  let body: String
  let color: String
  let pinned: Bool
  let created_at: String?
  let updated_at: String?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) { id = s }
    else { id = try c.decode(UUID.self, forKey: .id).uuidString }
    title = try c.decodeIfPresent(String.self, forKey: .title)
    body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
    color = try c.decodeIfPresent(String.self, forKey: .color) ?? NoteColor.mint.rawValue
    pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
    created_at = try c.decodeIfPresent(String.self, forKey: .created_at)
    updated_at = try c.decodeIfPresent(String.self, forKey: .updated_at)
  }

  var asNote: Note {
    Note(
      id: id,
      title: title,
      body: body,
      color: NoteColor(rawValue: color) ?? .mint,
      pinned: pinned,
      createdAt: Self.parseTimestamp(created_at) ?? Date(),
      updatedAt: Self.parseTimestamp(updated_at) ?? Date()
    )
  }

  private static func parseTimestamp(_ raw: String?) -> Date? {
    guard let raw, !raw.isEmpty else { return nil }
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let internet = ISO8601DateFormatter()
    internet.formatOptions = [.withInternetDateTime]
    return withFraction.date(from: raw) ?? internet.date(from: raw)
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, body, color, pinned, created_at, updated_at
  }
}
