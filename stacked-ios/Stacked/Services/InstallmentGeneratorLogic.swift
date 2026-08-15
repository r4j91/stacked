import Foundation

// Paridade lib/widgets/installment_generator_sheet.dart — cálculo de datas
enum InstallmentFrequency: String, CaseIterable, Identifiable {
  case monthly
  case biweekly
  case weekly

  var id: String { rawValue }

  var label: String {
    switch self {
    case .monthly: "Mensal"
    case .biweekly: "Quinzenal"
    case .weekly: "Semanal"
    }
  }
}

enum InstallmentGeneratorLogic {
  private static let monthAbbrev = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]

  static func generateDates(
    quantity: Int,
    firstDueDate: Date,
    frequency: InstallmentFrequency
  ) -> [Date] {
    let cal = Calendar.current
    return (0..<quantity).map { index in
      switch frequency {
      case .weekly:
        return cal.date(byAdding: .day, value: index * 7, to: firstDueDate) ?? firstDueDate
      case .biweekly:
        return cal.date(byAdding: .day, value: index * 14, to: firstDueDate) ?? firstDueDate
      case .monthly:
        return addMonths(firstDueDate, months: index, calendar: cal)
      }
    }
  }

  static func formatDate(_ date: Date) -> String {
    let cal = Calendar.current
    let day = cal.component(.day, from: date)
    let month = cal.component(.month, from: date)
    let year = cal.component(.year, from: date)
    let monthLabel = monthAbbrev[max(0, min(month - 1, 11))]
    return String(format: "%02d %@ %d", day, monthLabel, year)
  }

  /// Data civil local `yyyy-MM-dd` (coluna `data_vencimento`).
  static func isoDueDate(_ date: Date) -> String {
    TaskMapper.dateString(date)
  }

  /// `HH:mm` a partir do horário escolhido; `nil` se não houver hora.
  static func timeString(from time: Date?) -> String? {
    guard let time else { return nil }
    let cal = Calendar.current
    let h = cal.component(.hour, from: time)
    let m = cal.component(.minute, from: time)
    return String(format: "%02d:%02d", h, m)
  }

  static func formatTime(_ time: Date) -> String {
    timeString(from: time) ?? ""
  }

  /// Combina dia civil + hora (ou início do dia se `time` for nil).
  static func combine(date: Date, time: Date?) -> Date {
    let cal = Calendar.current
    guard let time else { return cal.startOfDay(for: date) }
    let h = cal.component(.hour, from: time)
    let m = cal.component(.minute, from: time)
    return cal.date(bySettingHour: h, minute: m, second: 0, of: date) ?? date
  }

  static func parseValor(_ raw: String) -> Double? {
    let trimmed = raw
      .replacingOccurrences(of: "R$", with: "", options: .caseInsensitive)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    var normalized = trimmed
    if normalized.contains(",") && normalized.contains(".") {
      normalized = normalized.replacingOccurrences(of: ".", with: "")
      normalized = normalized.replacingOccurrences(of: ",", with: ".")
    } else {
      normalized = normalized.replacingOccurrences(of: ",", with: ".")
    }
    guard let value = Double(normalized), value.isFinite else { return nil }
    return value
  }

  static func editingText(for valor: Double?) -> String {
    guard let valor, valor.isFinite else { return "" }
    return String(format: "%.2f", valor).replacingOccurrences(of: ".", with: ",")
  }

  /// PostgREST pode mandar numeric como Double, Int ou String.
  static func decodeValor<K: CodingKey>(_ c: KeyedDecodingContainer<K>, forKey key: K) -> Double? {
    if (try? c.decodeNil(forKey: key)) == true { return nil }
    if let d = try? c.decode(Double.self, forKey: key), d.isFinite { return d }
    if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
    if let s = try? c.decode(String.self, forKey: key) { return parseValor(s) }
    return nil
  }

  private static func addMonths(_ date: Date, months: Int, calendar: Calendar) -> Date {
    let day = calendar.component(.day, from: date)
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    let totalMonths = calendar.component(.month, from: date) - 1 + months
    let year = calendar.component(.year, from: date) + totalMonths / 12
    let month = totalMonths % 12 + 1
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = 1
    guard let firstOfMonth = calendar.date(from: comps) else { return date }
    let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
    let lastDay = range?.count ?? 28
    comps.day = min(day, lastDay)
    comps.hour = hour
    comps.minute = minute
    comps.second = 0
    return calendar.date(from: comps) ?? date
  }
}
