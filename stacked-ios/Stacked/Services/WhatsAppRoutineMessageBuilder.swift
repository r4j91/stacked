import Foundation

enum WhatsAppRoutineMessageBuilder {
  static func compose(
    taskTitle: String,
    dueDate: Date?,
    description: String?
  ) -> String {
    let title = sanitizeInline(taskTitle)
    let dateStr = formatDate(dueDate ?? Date())
    let descLines = parseDescriptionLines(description)

    var lines: [String] = []
    lines.append("*\(title) — \(dateStr)*")

    if descLines.isEmpty {
      return lines.joined(separator: "\n")
    }

    lines.append("")

    if descLines.count == 1 {
      lines.append("• *\(descLines[0])*")
    } else {
      lines.append("*\(descLines[0])*")
      lines.append("")
      for item in descLines.dropFirst() {
        lines.append("• *\(item)*")
      }
    }

    return lines.joined(separator: "\n")
  }

  private static func parseDescriptionLines(_ description: String?) -> [String] {
    guard let description else { return [] }
    return description
      .components(separatedBy: .newlines)
      .map { sanitizeInline($0) }
      .filter { !$0.isEmpty }
  }

  private static func formatDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "dd/MM/yyyy"
    return f.string(from: date)
  }

  private static func sanitizeInline(_ text: String) -> String {
    text
      .replacingOccurrences(of: "*", with: "")
      .replacingOccurrences(of: "_", with: "")
      .replacingOccurrences(of: "~", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
