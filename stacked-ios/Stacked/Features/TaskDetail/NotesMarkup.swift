import SwiftUI

/// Marcação leve estilo WhatsApp nas notas: `*negrito*`.
enum NotesMarkup {
  enum Run: Equatable {
    case plain(String)
    case bold(String)
  }

  /// Segmenta o texto em trechos normais / negrito (`*...*` em linha).
  static func runs(in source: String) -> [Run] {
    guard !source.isEmpty else { return [] }
    // Hot path das TaskRows: a maioria das descrições não tem markup.
    guard source.contains("*") else { return [.plain(source)] }
    let pattern = #"\*([^*\n]+)\*"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return [.plain(source)]
    }

    let ns = source as NSString
    let full = NSRange(location: 0, length: ns.length)
    var out: [Run] = []
    var cursor = 0

    for match in regex.matches(in: source, range: full) {
      let matchRange = match.range
      if matchRange.location > cursor {
        let before = ns.substring(with: NSRange(location: cursor, length: matchRange.location - cursor))
        if !before.isEmpty { out.append(.plain(before)) }
      }
      if match.numberOfRanges > 1 {
        let inner = ns.substring(with: match.range(at: 1))
        if !inner.isEmpty { out.append(.bold(inner)) }
      }
      cursor = matchRange.location + matchRange.length
    }

    if cursor < ns.length {
      let tail = ns.substring(from: cursor)
      if !tail.isEmpty { out.append(.plain(tail)) }
    }

    return out.isEmpty ? [.plain(source)] : out
  }

  /// Texto com negrito visível (SwiftUI `Text` concatenado — confiável no preview e nas rows).
  static func text(
    _ source: String,
    color: Color,
    size: CGFloat,
    weight: Font.Weight = .regular,
    boldWeight: Font.Weight = .semibold
  ) -> Text {
    let parts = runs(in: source)
    guard let first = parts.first else {
      return Text(source).font(.system(size: size, weight: weight)).foregroundStyle(color)
    }

    var combined: Text = segment(first, color: color, size: size, weight: weight, boldWeight: boldWeight)
    for part in parts.dropFirst() {
      combined = combined + segment(part, color: color, size: size, weight: weight, boldWeight: boldWeight)
    }
    return combined
  }

  private static func segment(
    _ run: Run,
    color: Color,
    size: CGFloat,
    weight: Font.Weight,
    boldWeight: Font.Weight
  ) -> Text {
    switch run {
    case .plain(let s):
      return Text(s)
        .font(.system(size: size, weight: weight))
        .foregroundColor(color)
    case .bold(let s):
      return Text(s)
        .font(.system(size: size, weight: boldWeight))
        .foregroundColor(color)
    }
  }
}

/// Preview de descrição com `*negrito*` aplicado.
struct NotesMarkupText: View {
  let source: String
  var color: Color
  var size: CGFloat = 13
  var weight: Font.Weight = .regular
  var boldWeight: Font.Weight = .semibold
  var lineLimit: Int? = nil

  var body: some View {
    // PERF_FASEC1: texto puro sem `*` — Text direto (mesma aparência).
    let view: Text = source.contains("*")
      ? NotesMarkup.text(
        source,
        color: color,
        size: size,
        weight: weight,
        boldWeight: boldWeight
      )
      : Text(source)
        .font(.system(size: size, weight: weight))
        .foregroundStyle(color)
    if let lineLimit {
      view.lineLimit(lineLimit).truncationMode(.tail)
    } else {
      view
    }
  }
}
