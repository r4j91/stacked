import Foundation
import SwiftUI

enum NoteColor: String, CaseIterable, Identifiable, Codable {
  case mint, ash, amber, violet, rose

  var id: String { rawValue }

  var label: String {
    switch self {
    case .mint: "Menta"
    case .ash: "Cinza"
    case .amber: "Âmbar"
    case .violet: "Violeta"
    case .rose: "Rosa"
    }
  }

  /// Fundo do post-it (Abismo-friendly).
  var fill: Color {
    switch self {
    case .mint: Color(hex: 0x1F3A36)
    case .ash: Color(hex: 0x2A2E36)
    case .amber: Color(hex: 0x3A2E1A)
    case .violet: Color(hex: 0x2C2438)
    case .rose: Color(hex: 0x3A2226)
    }
  }

  var ink: Color {
    switch self {
    case .mint: Color(hex: 0xC8F0EA)
    case .ash: Color(hex: 0xE4E8EE)
    case .amber: Color(hex: 0xF5E0B8)
    case .violet: Color(hex: 0xE4D4F8)
    case .rose: Color(hex: 0xF5C8CE)
    }
  }

  /// Rotação leve no mural (só visual).
  var muralRotation: Double {
    switch self {
    case .mint: -1.2
    case .ash: 1.0
    case .amber: 0.8
    case .violet: -0.6
    case .rose: 1.4
    }
  }
}

struct Note: Identifiable, Hashable {
  let id: String
  var title: String?
  var body: String
  var color: NoteColor
  var pinned: Bool
  var createdAt: Date
  var updatedAt: Date

  var displayTitle: String {
    let t = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !t.isEmpty { return t }
    let first = body.split(whereSeparator: \.isNewline).first.map(String.init)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return first.isEmpty ? "Nota" : first
  }

  var previewBody: String {
    let t = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if t.isEmpty { return body.trimmingCharacters(in: .whitespacesAndNewlines) }
    // Lista: título + resto do corpo
    return body.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Título / descrição ao virar tarefa.
  var taskSplit: (title: String, description: String?) {
    let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedTitle.isEmpty {
      return (trimmedTitle, trimmedBody.isEmpty ? nil : trimmedBody)
    }
    let lines = trimmedBody.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    let head = lines.first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let rest = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    return (head.isEmpty ? "Nota" : head, rest.isEmpty ? nil : rest)
  }
}

enum NotesDisplayMode: String {
  case mural
  case list
}

enum NotesDisplayModeStorage {
  static let key = "notesDisplayMode"
  static let defaultMode: NotesDisplayMode = .mural
  static var defaultRawValue: String { defaultMode.rawValue }

  static func mode(from raw: String) -> NotesDisplayMode {
    NotesDisplayMode(rawValue: raw) ?? defaultMode
  }
}
