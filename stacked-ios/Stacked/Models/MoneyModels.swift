import Foundation

struct MoneyDueItem: Identifiable, Equatable {
  let id: String
  let title: String
  let valor: Double
  let dueDate: Date?
  let dueLabel: String
  let projectName: String
  let parent: Task
  let subtask: Subtask
  let isIncome: Bool

  var subtitle: String {
    var parts: [String] = []
    if !dueLabel.isEmpty { parts.append(dueLabel) }
    if !projectName.isEmpty, projectName != "Sem projeto" { parts.append(projectName) }
    return parts.joined(separator: " · ")
  }

  var projectCaption: String {
    guard !projectName.isEmpty, projectName != "Sem projeto" else { return "" }
    return projectName
  }

  var isOverdue: Bool {
    guard let dueDate else { return false }
    let cal = Calendar.current
    return cal.startOfDay(for: dueDate) < cal.startOfDay(for: Date())
  }

  func matches(_ query: String) -> Bool {
    if title.localizedStandardContains(query) { return true }
    if dueLabel.localizedStandardContains(query) { return true }
    if projectName.localizedStandardContains(query) { return true }
    if parent.title.localizedStandardContains(query) { return true }
    if query.localizedStandardContains("atras"), isOverdue { return true }
    if isIncome, query.localizedStandardContains("receb") { return true }
    return false
  }
}

struct MoneyInstallmentGroup: Identifiable, Equatable {
  let id: String
  let title: String
  let snapshot: InstallmentProgress.Snapshot

  func matches(_ query: String) -> Bool {
    title.localizedStandardContains(query)
      || snapshot.label.localizedStandardContains(query)
  }
}

struct MoneyAccount: Identifiable, Equatable, Codable {
  var id: String
  var name: String
  var kind: Kind
  var balance: Double
  /// Dia do vencimento da fatura (1...31). Só crédito.
  var dueDay: Int?
  /// Dia de fechamento da fatura (1...31). Só crédito — define o ciclo.
  var closingDay: Int? = nil
  /// Valor aberto da fatura. Só crédito.
  var invoiceAmount: Double?
  /// Banco dono do cartão. Só crédito — pagar a fatura desconta deste saldo.
  var parentAccountId: String? = nil

  enum Kind: String, Codable, CaseIterable, Identifiable {
    case checking
    case credit
    case cash

    var id: String { rawValue }

    var label: String {
      switch self {
      case .checking: "Corrente"
      case .credit: "Crédito"
      case .cash: "Dinheiro"
      }
    }
  }

  var kindCaption: String {
    switch kind {
    case .checking:
      return "Saldo disponível"
    case .cash:
      return "Saldo · Dinheiro"
    case .credit:
      var parts: [String] = []
      if let closingDay, (1...31).contains(closingDay) {
        parts.append("Fecha \(closingDay)")
      }
      if let due = nextDueDate() {
        parts.append("vence \(MoneyCalendar.dayLabel(for: due))")
      } else if let dueDay, (1...31).contains(dueDay) {
        parts.append("vence \(dueDay)")
      }
      return parts.isEmpty ? "Fatura aberta" : parts.joined(separator: " · ")
    }
  }

  var limitUsage: Double? {
    guard kind == .credit, balance > 0 else { return nil }
    return min(1, max(0, (invoiceAmount ?? 0) / balance))
  }

  func nextDueDate(from now: Date = Date()) -> Date? {
    guard kind == .credit, let dueDay, (1...31).contains(dueDay) else { return nil }
    let cal = Calendar.current
    let today = cal.startOfDay(for: now)
    if let closingDay, (1...31).contains(closingDay) {
      let current = MoneyCalendar.invoiceCycle(containing: now, closingDay: closingDay)
      let prevClose = cal.date(byAdding: .day, value: -1, to: current.start) ?? current.start
      let prevDue = cal.startOfDay(for: MoneyCalendar.dueDate(forClosing: prevClose, dueDay: dueDay))
      if today <= prevDue {
        return prevDue
      }
      return MoneyCalendar.dueDate(forClosing: current.closingDate, dueDay: dueDay)
    }
    let thisMonth = MoneyCalendar.clampedDay(now, day: dueDay)
    if today <= thisMonth { return thisMonth }
    return MoneyCalendar.clampedDay(MoneyCalendar.addMonths(now, 1), day: dueDay)
  }

  func isInvoiceDueThisMonth(from now: Date = Date()) -> Bool {
    guard kind == .credit, (invoiceAmount ?? 0) > 0 else { return false }
    guard let due = nextDueDate(from: now) else { return false }
    return Calendar.current.isDate(due, equalTo: now, toGranularity: .month)
  }

  var displayAmount: Double {
    if kind == .credit, let invoiceAmount {
      return invoiceAmount
    }
    return balance
  }

  var highlightsAmount: Bool {
    kind == .credit && (invoiceAmount ?? 0) > 0
  }

  var isCard: Bool { kind == .credit }
}

/// Banco com cartões aninhados, ou um cartão sem conta pai.
struct MoneyAccountGroup: Identifiable, Equatable {
  var id: String
  var bank: MoneyAccount?
  var cards: [MoneyAccount]

  var isOrphan: Bool { bank == nil }
}

struct MoneyLedgerEntry: Identifiable, Equatable, Codable {
  var id: String
  var accountId: String
  var date: Date
  var amount: Double
  var isIncome: Bool
  var title: String
  var subtaskId: String?
  var installmentGroupId: String? = nil
  var installmentIndex: Int? = nil
  var installmentCount: Int? = nil
  var invoiceApplied: Bool = false

  var isCardInstallment: Bool {
    (installmentCount ?? 0) > 1 && installmentGroupId != nil
  }

  var installmentCaption: String? {
    guard isCardInstallment, let installmentIndex, let installmentCount else { return nil }
    return "Parcela \(installmentIndex)/\(installmentCount)"
  }

  enum CodingKeys: String, CodingKey {
    case id, accountId, date, amount, isIncome, title, subtaskId
    case installmentGroupId, installmentIndex, installmentCount, invoiceApplied
  }

  init(
    id: String,
    accountId: String,
    date: Date,
    amount: Double,
    isIncome: Bool,
    title: String,
    subtaskId: String? = nil,
    installmentGroupId: String? = nil,
    installmentIndex: Int? = nil,
    installmentCount: Int? = nil,
    invoiceApplied: Bool = false
  ) {
    self.id = id
    self.accountId = accountId
    self.date = date
    self.amount = amount
    self.isIncome = isIncome
    self.title = title
    self.subtaskId = subtaskId
    self.installmentGroupId = installmentGroupId
    self.installmentIndex = installmentIndex
    self.installmentCount = installmentCount
    self.invoiceApplied = invoiceApplied
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    accountId = try c.decode(String.self, forKey: .accountId)
    date = try c.decode(Date.self, forKey: .date)
    amount = try c.decode(Double.self, forKey: .amount)
    isIncome = try c.decode(Bool.self, forKey: .isIncome)
    title = try c.decode(String.self, forKey: .title)
    subtaskId = try c.decodeIfPresent(String.self, forKey: .subtaskId)
    installmentGroupId = try c.decodeIfPresent(String.self, forKey: .installmentGroupId)
    installmentIndex = try c.decodeIfPresent(Int.self, forKey: .installmentIndex)
    installmentCount = try c.decodeIfPresent(Int.self, forKey: .installmentCount)
    invoiceApplied = try c.decodeIfPresent(Bool.self, forKey: .invoiceApplied) ?? false
  }
}

enum MoneyCardInstallment {
  static let counts = [2, 3, 4, 5, 6, 10, 12, 18, 24]

  static func splitTotal(_ total: Double, count: Int) -> [Double] {
    let n = max(count, 1)
    let cents = Int((total * 100).rounded())
    let base = cents / n
    let remainder = cents - base * n
    return (0..<n).map { index in
      Double(base + (index == n - 1 ? remainder : 0)) / 100.0
    }
  }

  static func dates(purchase: Date, count: Int, account: MoneyAccount) -> [Date] {
    let n = max(count, 1)
    let first = Calendar.current.startOfDay(for: purchase)
    return (0..<n).map { index in
      if index == 0 { return first }
      let anchor = MoneyCalendar.shiftStatementAnchor(account: account, from: first, by: index)
      return MoneyCalendar.statementPeriod(for: account, containing: anchor).start
    }
  }

  static func firstInvoiceDueLabel(purchase: Date, account: MoneyAccount) -> String? {
    let period = MoneyCalendar.statementPeriod(for: account, containing: purchase)
    if let due = period.dueDate {
      return MoneyCalendar.dayLabel(for: due)
    }
    return period.title
  }
}

struct MoneyStatementLine: Identifiable, Equatable {
  let id: String
  let date: Date
  let title: String
  let amount: Double
  let isIncome: Bool
  let running: Double
  let dayLabel: String
  let caption: String?
}

struct MoneyMonthStatement: Equatable {
  let account: MoneyAccount
  let monthStart: Date
  let periodEnd: Date
  let periodTitle: String
  let periodCaption: String?
  let dueCaption: String?
  let invoiceDueDate: Date?
  let usesInvoiceCycle: Bool
  let opening: Double
  let income: Double
  let expense: Double
  let closing: Double
  let lines: [MoneyStatementLine]
  let amountLabel: String
}

enum MoneyCalendar {
  static let monthNames = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
  ]

  static func monthId(for date: Date) -> String {
    let cal = Calendar.current
    return String(format: "%04d-%02d", cal.component(.year, from: date), cal.component(.month, from: date))
  }

  static func monthStart(for date: Date) -> Date {
    Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
  }

  static func monthTitle(for date: Date) -> String {
    let cal = Calendar.current
    let month = cal.component(.month, from: date)
    let year = cal.component(.year, from: date)
    let name = monthNames[max(0, min(monthNames.count - 1, month - 1))]
    return "\(name) \(year)"
  }

  static func shiftMonth(_ date: Date, by months: Int) -> Date {
    Calendar.current.date(byAdding: .month, value: months, to: monthStart(for: date)) ?? date
  }

  static func dayLabel(for date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "d MMM"
    return f.string(from: date)
  }

  static func addMonths(_ date: Date, _ months: Int) -> Date {
    Calendar.current.date(byAdding: .month, value: months, to: date) ?? date
  }

  static func clampedDate(year: Int, month: Int, day: Int) -> Date {
    let cal = Calendar.current
    var comps = DateComponents(year: year, month: month, day: 1)
    let monthStart = cal.date(from: comps) ?? Date()
    let last = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 28
    comps.day = min(max(day, 1), last)
    return cal.startOfDay(for: cal.date(from: comps) ?? monthStart)
  }

  static func clampedDay(_ date: Date, day: Int) -> Date {
    let cal = Calendar.current
    return clampedDate(
      year: cal.component(.year, from: date),
      month: cal.component(.month, from: date),
      day: day
    )
  }

  struct InvoiceCycle: Equatable {
    let start: Date
    let end: Date

    var closingDate: Date {
      Calendar.current.date(byAdding: .day, value: -1, to: end) ?? start
    }
  }

  static func invoiceCycle(containing date: Date, closingDay: Int) -> InvoiceCycle {
    let cal = Calendar.current
    let day = cal.startOfDay(for: date)
    let closeThisMonth = clampedDay(day, day: closingDay)
    let closing = day <= closeThisMonth
      ? closeThisMonth
      : clampedDay(addMonths(closeThisMonth, 1), day: closingDay)
    let prevClosing = clampedDay(addMonths(closing, -1), day: closingDay)
    let start = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: prevClosing) ?? prevClosing)
    let end = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: closing) ?? closing)
    return InvoiceCycle(start: start, end: end)
  }

  static func dueDate(forClosing closing: Date, dueDay: Int) -> Date {
    let closeDay = Calendar.current.component(.day, from: closing)
    if dueDay > closeDay {
      return clampedDay(closing, day: dueDay)
    }
    return clampedDay(addMonths(closing, 1), day: dueDay)
  }

  struct StatementPeriod: Equatable {
    let start: Date
    let end: Date
    let title: String
    let caption: String?
    let dueCaption: String?
    let dueDate: Date?
    let usesInvoiceCycle: Bool
  }

  static func statementPeriod(for account: MoneyAccount, containing date: Date) -> StatementPeriod {
    if account.kind == .credit, let closingDay = account.closingDay, (1...31).contains(closingDay) {
      let cycle = invoiceCycle(containing: date, closingDay: closingDay)
      let lastDay = cycle.closingDate
      let caption = "\(dayLabel(for: cycle.start)) – \(dayLabel(for: lastDay))"
      var dueDate: Date?
      var dueCaption: String?
      var title = monthTitle(for: lastDay)
      if let dueDay = account.dueDay, (1...31).contains(dueDay) {
        let due = Self.dueDate(forClosing: lastDay, dueDay: dueDay)
        dueDate = due
        dueCaption = "Vence \(dayLabel(for: due))"
        title = monthTitle(for: due)
      }
      return StatementPeriod(
        start: cycle.start,
        end: cycle.end,
        title: title,
        caption: caption,
        dueCaption: dueCaption,
        dueDate: dueDate,
        usesInvoiceCycle: true
      )
    }
    let start = monthStart(for: date)
    return StatementPeriod(
      start: start,
      end: shiftMonth(start, by: 1),
      title: monthTitle(for: start),
      caption: nil,
      dueCaption: nil,
      dueDate: nil,
      usesInvoiceCycle: false
    )
  }

  static func shiftStatementAnchor(account: MoneyAccount, from date: Date, by steps: Int) -> Date {
    if account.kind == .credit, let closingDay = account.closingDay, (1...31).contains(closingDay) {
      let cycle = invoiceCycle(containing: date, closingDay: closingDay)
      let shiftedClose = clampedDay(addMonths(cycle.closingDate, steps), day: closingDay)
      return shiftedClose
    }
    return shiftMonth(monthStart(for: date), by: steps)
  }

  static func isCurrentOrFuturePeriod(account: MoneyAccount, anchor: Date, now: Date = Date()) -> Bool {
    let viewing = statementPeriod(for: account, containing: anchor)
    let current = statementPeriod(for: account, containing: now)
    return viewing.start >= current.start
  }

  /// Semanas do mês com início na segunda (salário). Intervalos `[start, end)` cortados no mês.
  static func mondayWeeks(inMonthStarting monthStart: Date) -> [(index: Int, start: Date, end: Date)] {
    let cal = Calendar.current
    let monthEnd = shiftMonth(monthStart, by: 1)
    var weeks: [(Int, Date, Date)] = []
    var cursor = cal.startOfDay(for: monthStart)
    var index = 1
    while cursor < monthEnd {
      let end = min(nextMonday(afterOrFrom: cursor), monthEnd)
      weeks.append((index, cursor, end))
      cursor = end
      index += 1
    }
    return weeks
  }

  /// Próxima segunda a partir de `date`. Se já for segunda, avança 7 dias.
  static func nextMonday(afterOrFrom date: Date) -> Date {
    let cal = Calendar.current
    let day = cal.startOfDay(for: date)
    let weekday = cal.component(.weekday, from: day) // 1=dom … 2=seg
    if weekday == 2 {
      return cal.date(byAdding: .day, value: 7, to: day) ?? day
    }
    let delta = (9 - weekday) % 7
    return cal.date(byAdding: .day, value: delta == 0 ? 7 : delta, to: day) ?? day
  }

  static func weekRangeLabel(start: Date, endExclusive: Date) -> String {
    let cal = Calendar.current
    let last = cal.date(byAdding: .day, value: -1, to: endExclusive) ?? start
    if cal.isDate(start, inSameDayAs: last) {
      return dayLabel(for: start)
    }
    return "\(dayLabel(for: start)) – \(dayLabel(for: last))"
  }

  /// Parse `YYYY-MM` → início do mês; `nil` se inválido / Sem data.
  static func monthStart(fromMonthId id: String) -> Date? {
    let parts = id.split(separator: "-")
    guard parts.count == 2,
          let year = Int(parts[0]),
          let month = Int(parts[1]),
          (1...12).contains(month)
    else { return nil }
    return clampedDate(year: year, month: month, day: 1)
  }
}

struct MoneyStatementRoute: Identifiable, Hashable {
  let accountId: String
  var id: String { accountId }
}

struct MoneyMonthGroup: Identifiable, Equatable {
  let id: String
  let title: String
  let year: Int?
  let items: [MoneyDueItem]
  let completedItems: [MoneyDueItem]

  var total: Double { items.reduce(0) { $0 + $1.valor } }
  var count: Int { items.count }
  var completedTotal: Double { completedItems.reduce(0) { $0 + $1.valor } }
  var completedCount: Int { completedItems.count }
  var completedSectionId: String { "\(id)-done" }
  var calendarMonthId: String {
    if id.hasPrefix("recv-") { return String(id.dropFirst(5)) }
    return id
  }

  func nameMatches(_ query: String) -> Bool {
    if title.localizedStandardContains(query) { return true }
    if id.localizedStandardContains(query) { return true }
    if let year {
      let y = String(year)
      if y == query || (query.count >= 2 && y.localizedStandardContains(query)) { return true }
    }
    return false
  }

  func matches(_ query: String) -> Bool {
    nameMatches(query)
      || items.contains { $0.matches(query) }
      || completedItems.contains { $0.matches(query) }
  }
}

enum MoneyDueOutline: Identifiable, Equatable {
  case month(MoneyMonthGroup)
  case year(year: Int, months: [MoneyMonthGroup])

  var id: String {
    switch self {
    case .month(let group):
      return group.id
    case .year(let year, _):
      return "year-\(year)"
    }
  }

  var title: String {
    switch self {
    case .month(let group):
      return group.title
    case .year(let year, _):
      return "\(year)"
    }
  }

  var months: [MoneyMonthGroup] {
    switch self {
    case .month(let group):
      return [group]
    case .year(_, let months):
      return months
    }
  }

  var items: [MoneyDueItem] { months.flatMap(\.items) }
  var total: Double { items.reduce(0) { $0 + $1.valor } }
  var count: Int { items.count }
}

struct MoneyObligationLink: Codable, Equatable {
  var accountId: String
  var valor: Double
}

// MARK: - Fluxo de caixa (mês civil)

enum MoneyCashFlowLineKind: String, Equatable {
  case income
  case expense
  case transfer
  case obligation
  case invoice
  case cardPurchase

  var label: String {
    switch self {
    case .income: "Entrada"
    case .expense: "Saída"
    case .transfer: "Transferência"
    case .obligation: "A pagar"
    case .invoice: "Fatura"
    case .cardPurchase: "Cartão"
    }
  }
}

struct MoneyCashFlowLine: Identifiable, Equatable {
  let id: String
  let date: Date
  let title: String
  let subtitle: String?
  let amount: Double
  let kind: MoneyCashFlowLineKind
  /// Entra no saldo líquido (corrente/dinheiro). Compras no cartão ficam de fora.
  let affectsCash: Bool
  /// Ainda não saiu do caixa (obrigação / fatura pendente).
  let isProjected: Bool
  let dayLabel: String
}

struct MoneyCashFlowWeek: Identifiable, Equatable {
  let id: String
  let index: Int
  let title: String
  let rangeLabel: String
  let start: Date
  let end: Date
  let opening: Double
  let lines: [MoneyCashFlowLine]
  let income: Double
  let expense: Double
  let projectedOut: Double
  let projectedIn: Double
  let closing: Double

  var net: Double { closing - opening }
  var isNegative: Bool { closing < -0.005 }
}

struct MoneyCashFlowReport: Equatable {
  let monthId: String
  let title: String
  let monthStart: Date
  let monthEnd: Date
  let opening: Double
  let lines: [MoneyCashFlowLine]
  let weeks: [MoneyCashFlowWeek]
  let income: Double
  let expense: Double
  let transferNet: Double
  let projectedOut: Double
  let projectedIn: Double
  let cardPurchases: Double
  let closingRealized: Double
  let closingProjected: Double

  var netRealized: Double { closingRealized - opening }
  var netProjected: Double { closingProjected - opening }
  var isNegativeProjected: Bool { closingProjected < -0.005 }
  var isNegativeRealized: Bool { closingRealized < -0.005 }
  var isNegativeMonthNet: Bool { netProjected < -0.005 }

  /// Ex.: "agosto" — rótulo do saldo que veio do mês anterior.
  var priorMonthName: String {
    let prior = MoneyCalendar.shiftMonth(monthStart, by: -1)
    let month = Calendar.current.component(.month, from: prior)
    return MoneyCalendar.monthNames[max(0, min(11, month - 1))].lowercased()
  }

  var monthName: String {
    let month = Calendar.current.component(.month, from: monthStart)
    return MoneyCalendar.monthNames[max(0, min(11, month - 1))].lowercased()
  }

  var openingLabel: String { "Saldo de \(priorMonthName)" }

  var cashLines: [MoneyCashFlowLine] { lines.filter(\.affectsCash) }
  var cardLines: [MoneyCashFlowLine] { lines.filter { $0.kind == .cardPurchase } }
}

struct MoneyCashFlowRoute: Identifiable, Hashable {
  let monthId: String
  var id: String { monthId }
}
