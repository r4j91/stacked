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

  static func isoDueDate(_ date: Date) -> String {
    let cal = Calendar.current
    let start = cal.startOfDay(for: date)
    return ISO8601DateFormatter().string(from: start)
  }

  static func parseValor(_ raw: String) -> Double? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
  }

  private static func addMonths(_ date: Date, months: Int, calendar: Calendar) -> Date {
    let day = calendar.component(.day, from: date)
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
    return calendar.date(from: comps) ?? date
  }
}
