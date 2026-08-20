import Foundation
import Supabase

@MainActor
@Observable
final class MoneyStore {
  static let shared = MoneyStore()

  private(set) var dueItems: [MoneyDueItem] = []
  private(set) var completedItems: [MoneyDueItem] = []
  private(set) var receivableItems: [MoneyDueItem] = []
  private(set) var completedReceivableItems: [MoneyDueItem] = []
  private(set) var monthItems: [MoneyDueItem] = []
  private(set) var monthReceivableItems: [MoneyDueItem] = []
  private(set) var monthGroups: [MoneyMonthGroup] = []
  private(set) var receivableMonthGroups: [MoneyMonthGroup] = []
  private(set) var dueOutline: [MoneyDueOutline] = []
  private(set) var receivableOutline: [MoneyDueOutline] = []
  private(set) var installments: [MoneyInstallmentGroup] = []
  private(set) var accounts: [MoneyAccount] = []
  private(set) var isLoading = false
  private(set) var error: String?

  var monthTotal: Double {
    monthItems.reduce(0) { $0 + $1.valor }
  }

  var monthCount: Int { monthItems.count }

  var monthSubtitle: String {
    var parts: [String] = []
    if monthCount == 0 {
      parts.append("Nenhum item")
    } else {
      parts.append(monthCount == 1 ? "1 item" : "\(monthCount) itens")
    }
    if let credit = nextInvoiceCaption {
      parts.append(credit)
    }
    return parts.joined(separator: " · ")
  }

  /// Saldo líquido (corrente + dinheiro). Cartão não entra.
  var liquidBalance: Double {
    accounts
      .filter { $0.kind == .checking || $0.kind == .cash }
      .reduce(0) { $0 + $1.balance }
  }

  /// Saldo atual menos a pagar do mês e faturas que vencem neste mês.
  var projectedLeftover: Double {
    liquidBalance - monthTotal - openInvoiceTotal
  }

  var accountsSubtitle: String {
    if !accounts.contains(where: { $0.kind == .checking || $0.kind == .cash }) {
      return "Nenhuma conta"
    }
    return "Sobra projetada \(CurrencyFormat.brl(projectedLeftover))"
  }

  var openInvoiceTotal: Double {
    accounts
      .filter { $0.isInvoiceDueThisMonth() }
      .reduce(0) { $0 + ($1.invoiceAmount ?? 0) }
  }

  var hubSnapshotTotal: Double { monthTotal + openInvoiceTotal }

  var hubSnapshotSubtitle: String {
    var parts: [String] = []
    if monthCount > 0 {
      parts.append("A pagar \(CurrencyFormat.brl(monthTotal))")
    }
    if let credit = nextInvoiceCaption {
      parts.append(credit)
    } else if openInvoiceTotal > 0 {
      parts.append("Faturas \(CurrencyFormat.brl(openInvoiceTotal))")
    }
    if parts.isEmpty { return "Nada pendente" }
    return parts.joined(separator: " · ")
  }

  var showsHubSnapshot: Bool {
    !accounts.isEmpty || monthCount > 0
  }

  var currentMonthGroupId: String {
    MoneyCalendar.monthId(for: Date())
  }

  var nextInvoiceCaption: String? {
    guard let upcoming = nextInvoice else { return nil }
    guard Calendar.current.isDate(upcoming.due, equalTo: Date(), toGranularity: .month) else {
      return nil
    }
    return "\(upcoming.account.name) vence \(MoneyCalendar.dayLabel(for: upcoming.due))"
  }

  var nextInvoice: (account: MoneyAccount, due: Date)? {
    accounts.compactMap { account -> (MoneyAccount, Date)? in
      guard account.kind == .credit else { return nil }
      guard (account.invoiceAmount ?? 0) > 0 else { return nil }
      guard let due = account.nextDueDate() else { return nil }
      return (account, due)
    }
    .min { $0.1 < $1.1 }
  }

  private static let accountsKeyPrefix = "money.accounts.v1."
  private static let linksKeyPrefix = "money.obligationLinks.v1."
  private static let ledgerKeyPrefix = "money.ledger.v1."

  private var obligationLinks: [String: MoneyObligationLink] = [:]
  private(set) var ledger: [MoneyLedgerEntry] = []

  private init() {
    hydrateAccounts()
    hydrateLinks()
    hydrateLedger()
  }

  func resetForSignOut() {
    dueItems = []
    completedItems = []
    receivableItems = []
    completedReceivableItems = []
    monthItems = []
    monthReceivableItems = []
    monthGroups = []
    receivableMonthGroups = []
    dueOutline = []
    receivableOutline = []
    installments = []
    accounts = []
    obligationLinks = [:]
    ledger = []
    isLoading = false
    error = nil
    if let userId = SupabaseService.client.auth.currentUser?.id {
      UserDefaults.standard.removeObject(forKey: Self.accountsKey(userId))
      UserDefaults.standard.removeObject(forKey: Self.linksKey(userId))
      UserDefaults.standard.removeObject(forKey: Self.ledgerKey(userId))
    }
  }

  func load() async {
    hydrateAccounts()
    hydrateLinks()
    hydrateLedger()
    guard SupabaseService.client.auth.currentUser != nil else { return }
    isLoading = dueItems.isEmpty && installments.isEmpty
    error = nil
    do {
      await mergeRemoteMoney()
      postInstallmentsToOpenInvoice()
      async let pendingReq = SubtaskRepository.shared.fetchPendingValorEntries()
      async let completedReq = SubtaskRepository.shared.fetchCompletedValorEntries()
      let pendingEntries = try await pendingReq
      let completedEntries = try await completedReq
      let pending = pendingEntries.compactMap(Self.dueItem(from:))
      let completed = completedEntries.compactMap(Self.dueItem(from:))
      dueItems = pending.filter { !$0.isIncome }.sorted(by: Self.sortDue)
      receivableItems = pending.filter(\.isIncome).sorted(by: Self.sortDue)
      completedItems = completed.filter { !$0.isIncome }.sorted(by: Self.sortDue)
      completedReceivableItems = completed.filter(\.isIncome).sorted(by: Self.sortDue)
      monthItems = dueItems.filter(Self.isInCurrentMonth)
      monthReceivableItems = receivableItems.filter(Self.isInCurrentMonth)
      rebuildDueGroups()

      let parentIds = Array(
        Set(
          pendingEntries.compactMap { entry -> String? in
            guard InstallmentProgress.isInstallmentTitle(entry.subtask.title) else { return nil }
            return entry.parent.id
          }
        )
      )
      if parentIds.isEmpty {
        installments = []
      } else {
        let siblings = try await SubtaskRepository.shared.fetchEntriesForParentIds(parentIds)
        installments = Self.installmentGroups(from: siblings)
      }
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  func addAccount(_ account: MoneyAccount) {
    accounts.append(account)
    persistAccounts()
  }

  func updateAccount(_ account: MoneyAccount) {
    guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
    accounts[index] = account
    persistAccounts()
  }

  func deleteAccount(id: String) {
    let childIds = accounts.filter { $0.parentAccountId == id }.map(\.id)
    let removed = Set([id] + childIds)
    accounts.removeAll { removed.contains($0.id) }
    obligationLinks = obligationLinks.filter { !removed.contains($0.value.accountId) }
    ledger.removeAll { removed.contains($0.accountId) }
    persistAccounts()
    persistLinks()
    persistLedger()
    let removedIds = Array(removed)
    _Concurrency.Task {
      try? await MoneyRepository.deleteAccounts(ids: removedIds)
    }
  }

  func bankAccounts(excluding id: String? = nil) -> [MoneyAccount] {
    accounts.filter { account in
      (account.kind == .checking || account.kind == .cash)
        && account.id != id
    }
    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  func cards(forBankId id: String) -> [MoneyAccount] {
    accounts.filter { $0.kind == .credit && $0.parentAccountId == id }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  func account(id: String) -> MoneyAccount? {
    accounts.first { $0.id == id }
  }

  func displayName(for account: MoneyAccount) -> String {
    if account.kind == .credit, let parentId = account.parentAccountId, let bank = self.account(id: parentId) {
      return "\(bank.name) · \(account.name)"
    }
    return account.name
  }

  /// Banco + cartões aninhados; cartões sem banco ficam no fim.
  func accountOutline() -> [(account: MoneyAccount, nested: Bool)] {
    accountGroups().flatMap { group in
      var rows: [(account: MoneyAccount, nested: Bool)] = []
      if let bank = group.bank {
        rows.append((bank, false))
        rows.append(contentsOf: group.cards.map { ($0, true) })
      } else {
        rows.append(contentsOf: group.cards.map { ($0, false) })
      }
      return rows
    }
  }

  func accountGroups() -> [MoneyAccountGroup] {
    var groups: [MoneyAccountGroup] = []
    let banks = accounts.filter { $0.kind != .credit }
      .sorted { lhs, rhs in
        let rank: (MoneyAccount.Kind) -> Int = { $0 == .checking ? 0 : 1 }
        if rank(lhs.kind) != rank(rhs.kind) { return rank(lhs.kind) < rank(rhs.kind) }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
      }
    for bank in banks {
      groups.append(MoneyAccountGroup(id: bank.id, bank: bank, cards: cards(forBankId: bank.id)))
    }
    let orphans = accounts.filter { $0.kind == .credit && ($0.parentAccountId == nil || account(id: $0.parentAccountId ?? "") == nil) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    for card in orphans {
      groups.append(MoneyAccountGroup(id: card.id, bank: nil, cards: [card]))
    }
    return groups
  }

  func applySpend(accountId: String, amount: Double) {
    applyMovement(accountId: accountId, amount: amount, isIncome: false, title: nil)
  }

  func applyMovement(
    accountId: String,
    amount: Double,
    isIncome: Bool,
    title: String? = nil,
    date: Date = Date(),
    installmentCount: Int = 1
  ) {
    if !isIncome, installmentCount > 1, account(id: accountId)?.kind == .credit {
      applyCardInstallment(
        accountId: accountId,
        total: amount,
        title: title,
        date: date,
        count: installmentCount
      )
      return
    }
    applyAccountDelta(accountId: accountId, amount: amount, reverse: isIncome)
    appendLedger(
      accountId: accountId,
      amount: amount,
      isIncome: isIncome,
      title: title,
      subtaskId: nil,
      date: date
    )
  }

  func installmentPlan(for entryId: String) -> [MoneyLedgerEntry] {
    guard let entry = ledgerEntry(id: entryId), let group = entry.installmentGroupId else {
      return ledgerEntry(id: entryId).map { [$0] } ?? []
    }
    return ledger
      .filter { $0.installmentGroupId == group }
      .sorted { ($0.installmentIndex ?? 0) < ($1.installmentIndex ?? 0) }
  }

  func futureInstallmentTotal(for accountId: String) -> Double {
    unpostedInstallments(accountId: accountId).reduce(0) { $0 + $1.amount }
  }

  func futureInstallmentCount(for accountId: String) -> Int {
    unpostedInstallments(accountId: accountId).count
  }

  func limitUsage(for account: MoneyAccount) -> Double? {
    guard account.kind == .credit, account.balance > 0 else { return nil }
    let used = (account.invoiceAmount ?? 0) + futureInstallmentTotal(for: account.id)
    return min(1, max(0, used / account.balance))
  }

  func futureInstallmentCaption(for account: MoneyAccount) -> String? {
    let count = futureInstallmentCount(for: account.id)
    guard count > 0 else { return nil }
    let total = futureInstallmentTotal(for: account.id)
    let n = count == 1 ? "1 parcela" : "\(count) parcelas"
    return "\(CurrencyFormat.brl(total)) em \(n)"
  }

  func accountsMatchingLedger(query: String) -> Set<String> {
    Set(
      ledger.filter { $0.title.localizedStandardContains(query) }.map(\.accountId)
    )
  }

  func ledgerEntry(id: String) -> MoneyLedgerEntry? {
    ledger.first { $0.id == id }
  }

  func updateLedgerEntry(
    id: String,
    accountId: String,
    amount: Double,
    isIncome: Bool,
    title: String?,
    date: Date? = nil,
    installmentCount: Int = 1
  ) {
    guard amount > 0, let index = ledger.firstIndex(where: { $0.id == id }) else { return }
    var entry = ledger[index]
    let count = max(installmentCount, 1)
    if entry.isCardInstallment || (count > 1 && account(id: accountId)?.kind == .credit && !isIncome) {
      replaceCardInstallment(
        entry: entry,
        accountId: accountId,
        total: amount,
        isIncome: isIncome,
        title: title,
        date: date ?? entry.date,
        count: count
      )
      return
    }
    applyAccountDelta(accountId: entry.accountId, amount: entry.amount, reverse: !entry.isIncome)
    applyAccountDelta(accountId: accountId, amount: amount, reverse: isIncome)
    let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    entry.accountId = accountId
    entry.amount = amount
    entry.isIncome = isIncome
    entry.title = trimmed.isEmpty ? (isIncome ? "Entrada" : "Saída") : trimmed
    if let date {
      entry.date = date
    }
    ledger[index] = entry
    persistLedger()
  }

  func deleteLedgerEntry(id: String) {
    guard let entry = ledger.first(where: { $0.id == id }) else { return }
    if entry.isCardInstallment, let group = entry.installmentGroupId {
      deleteCardInstallment(groupId: group)
      return
    }
    applyAccountDelta(accountId: entry.accountId, amount: entry.amount, reverse: !entry.isIncome)
    ledger.removeAll { $0.id == id }
    persistLedger(deletedIds: [id])
  }

  func transferableAccounts() -> [MoneyAccount] {
    accounts.filter { $0.kind != .credit }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  /// Tira o valor da conta origem e soma na destino. Cartão não entra — fatura se paga no extrato.
  @discardableResult
  func transfer(
    fromAccountId: String,
    toAccountId: String,
    amount: Double,
    title: String? = nil,
    date: Date = Date()
  ) -> String? {
    guard fromAccountId != toAccountId else { return "Escolha duas contas diferentes." }
    guard amount > 0 else { return "Informe um valor." }
    guard let from = account(id: fromAccountId), from.kind != .credit else {
      return "Não dá para transferir a partir de um cartão."
    }
    guard let to = account(id: toAccountId), to.kind != .credit else {
      return "Não dá para transferir para um cartão. Pague a fatura pelo extrato."
    }
    let note = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let fromTitle = note.isEmpty
      ? "Transferência para \(to.name)"
      : "Transferência para \(to.name) · \(note)"
    let toTitle = note.isEmpty
      ? "Transferência de \(from.name)"
      : "Transferência de \(from.name) · \(note)"
    applyMovement(
      accountId: from.id,
      amount: amount,
      isIncome: false,
      title: fromTitle,
      date: date
    )
    applyMovement(
      accountId: to.id,
      amount: amount,
      isIncome: true,
      title: toTitle,
      date: date
    )
    return nil
  }

  /// Paga a fatura do cartão com o saldo do banco pai.
  @discardableResult
  func payInvoice(cardId: String) -> String? {
    guard let card = account(id: cardId), card.kind == .credit else {
      return "Cartão não encontrado."
    }
    let amount = card.invoiceAmount ?? 0
    guard amount > 0 else { return "Fatura já está zerada." }
    guard let parentId = card.parentAccountId, account(id: parentId) != nil else {
      return "Ligue este cartão a um banco para pagar a fatura."
    }
    applyMovement(
      accountId: parentId,
      amount: amount,
      isIncome: false,
      title: "Fatura \(card.name)"
    )
    applyMovement(
      accountId: cardId,
      amount: amount,
      isIncome: true,
      title: "Pagamento da fatura"
    )
    return nil
  }

  func statement(accountId: String, monthStart: Date) -> MoneyMonthStatement? {
    guard let account = self.account(id: accountId) else { return nil }
    let period = MoneyCalendar.statementPeriod(for: account, containing: monthStart)
    let current = MoneyCalendar.statementPeriod(for: account, containing: Date())
    let isFuturePreview = period.start >= current.end
    let entries = ledger
      .filter { $0.accountId == accountId && $0.date >= period.start && $0.date < period.end }
      .sorted { $0.date < $1.date }

    let income = entries.filter(\.isIncome).reduce(0) { $0 + $1.amount }
    let expense = entries.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }

    let opening: Double
    if isFuturePreview {
      opening = 0
    } else {
      let later = ledger.filter { entry in
        entry.accountId == accountId
          && entry.date >= period.start
          && isPostedToOpenInvoice(entry, account: account, currentEnd: current.end)
      }
      let laterNet = later.reduce(0.0) { $0 + signedAmount($1, account: account) }
      opening = currentAmount(account) - laterNet
    }
    let closing = opening + entries.reduce(0.0) { $0 + signedAmount($1, account: account) }

    var running = opening
    let lines: [MoneyStatementLine] = entries.map { entry in
      running += signedAmount(entry, account: account)
      return MoneyStatementLine(
        id: entry.id,
        date: entry.date,
        title: entry.title,
        amount: entry.amount,
        isIncome: entry.isIncome,
        running: running,
        dayLabel: MoneyCalendar.dayLabel(for: entry.date),
        caption: entry.installmentCaption
      )
    }

    return MoneyMonthStatement(
      account: account,
      monthStart: period.start,
      periodEnd: period.end,
      periodTitle: period.title,
      periodCaption: period.caption,
      dueCaption: period.dueCaption,
      invoiceDueDate: period.dueDate,
      usesInvoiceCycle: period.usesInvoiceCycle,
      opening: opening,
      income: income,
      expense: expense,
      closing: closing,
      lines: lines,
      amountLabel: account.kind == .credit ? "Fatura" : "Saldo"
    )
  }

  /// Fluxo de caixa do mês civil (contas líquidas + a pagar + faturas + compras no cartão).
  func cashFlow(monthId: String) -> MoneyCashFlowReport? {
    guard let monthStart = MoneyCalendar.monthStart(fromMonthId: monthId) else { return nil }
    let monthEnd = MoneyCalendar.shiftMonth(monthStart, by: 1)
    let cal = Calendar.current
    let liquidIds = Set(
      accounts
        .filter { $0.kind == .checking || $0.kind == .cash }
        .map(\.id)
    )
    let creditIds = Set(accounts.filter { $0.kind == .credit }.map(\.id))
    let accountName: [String: String] = Dictionary(
      uniqueKeysWithValues: accounts.map { ($0.id, $0.name) }
    )

    let opening = liquidOpeningBalance(liquidIds: liquidIds, at: monthStart)

    /// Só esconde o projetado quando a subtarefa já gerou lançamento no extrato (conclusão).
    let settledSubtaskIds = Set(ledger.compactMap(\.subtaskId).filter { !$0.isEmpty })

    var built: [MoneyCashFlowLine] = []
    var seenLineIds = Set<String>()

    func appendUnique(_ line: MoneyCashFlowLine) {
      guard seenLineIds.insert(line.id).inserted else { return }
      built.append(line)
    }

    for entry in ledger where entry.date >= monthStart && entry.date < monthEnd {
      let isTransfer = entry.title.hasPrefix("Transferência")
      let day = cal.startOfDay(for: entry.date)
      if liquidIds.contains(entry.accountId) {
        let kind: MoneyCashFlowLineKind
        if isTransfer {
          kind = .transfer
        } else {
          kind = entry.isIncome ? .income : .expense
        }
        let signed = entry.isIncome ? entry.amount : -entry.amount
        appendUnique(
          MoneyCashFlowLine(
            id: entry.id,
            date: day,
            title: entry.title,
            subtitle: [
              accountName[entry.accountId],
              entry.installmentCaption,
            ].compactMap { $0 }.joined(separator: " · ").moneyNilIfEmpty,
            amount: signed,
            kind: kind,
            affectsCash: true,
            isProjected: false,
            dayLabel: MoneyCalendar.dayLabel(for: day)
          )
        )
      } else if creditIds.contains(entry.accountId), !entry.isIncome, !isTransfer {
        appendUnique(
          MoneyCashFlowLine(
            id: "card-\(entry.id)",
            date: day,
            title: entry.title,
            subtitle: [
              accountName[entry.accountId],
              entry.installmentCaption,
              "não sai do caixa",
            ].compactMap { $0 }.joined(separator: " · ").moneyNilIfEmpty,
            amount: -entry.amount,
            kind: .cardPurchase,
            affectsCash: false,
            isProjected: false,
            dayLabel: MoneyCalendar.dayLabel(for: day)
          )
        )
      }
    }

    let dueGroup = monthGroups.first { $0.id == monthId }
    for item in (dueGroup?.items ?? []) + pendingReceivables(in: monthId) {
      guard item.parent.includeInCashFlow, item.subtask.includeInCashFlow else { continue }
      if let sid = item.subtask.id, settledSubtaskIds.contains(sid) { continue }
      let due = cal.startOfDay(for: item.dueDate ?? monthStart)
      guard due >= monthStart && due < monthEnd else { continue }
      let signed = item.isIncome ? item.valor : -item.valor
      appendUnique(
        MoneyCashFlowLine(
          id: "due-\(item.id)",
          date: due,
          title: item.title,
          subtitle: [
            item.projectName,
            item.isIncome ? "a receber" : "a pagar",
          ].filter { !$0.isEmpty }.joined(separator: " · ").moneyNilIfEmpty,
          amount: signed,
          kind: item.isIncome ? .income : .obligation,
          affectsCash: true,
          isProjected: true,
          dayLabel: item.dueLabel
        )
      )
    }

    for account in accounts where account.kind == .credit {
      let invoice = account.invoiceAmount ?? 0
      guard invoice > 0, let dueRaw = account.nextDueDate() else { continue }
      let due = cal.startOfDay(for: dueRaw)
      guard MoneyCalendar.monthId(for: due) == monthId else { continue }
      appendUnique(
        MoneyCashFlowLine(
          id: "invoice-\(account.id)",
          date: due,
          title: "Fatura \(account.name)",
          subtitle: "vence \(MoneyCalendar.dayLabel(for: due))",
          amount: -invoice,
          kind: .invoice,
          affectsCash: true,
          isProjected: true,
          dayLabel: MoneyCalendar.dayLabel(for: due)
        )
      )
    }

    built.sort {
      if $0.date != $1.date { return $0.date < $1.date }
      if $0.isProjected != $1.isProjected { return !$0.isProjected && $1.isProjected }
      return $0.title.localizedStandardCompare($1.title) == .orderedAscending
    }

    let income = built.filter { $0.affectsCash && $0.kind == .income && !$0.isProjected }.reduce(0) { $0 + $1.amount }
    let expense = built
      .filter { $0.affectsCash && $0.kind == .expense && !$0.isProjected }
      .reduce(0) { $0 + abs($1.amount) }
    let transferNet = built
      .filter { $0.affectsCash && $0.kind == .transfer }
      .reduce(0) { $0 + $1.amount }
    let projectedOut = built
      .filter { $0.affectsCash && $0.isProjected && $0.amount < 0 }
      .reduce(0) { $0 + abs($1.amount) }
    let projectedIn = built
      .filter { $0.affectsCash && $0.isProjected && $0.amount > 0 }
      .reduce(0) { $0 + $1.amount }
    let cardPurchases = built
      .filter { $0.kind == .cardPurchase }
      .reduce(0) { $0 + abs($1.amount) }

    let realizedDelta = built
      .filter { $0.affectsCash && !$0.isProjected }
      .reduce(0) { $0 + $1.amount }
    let projectedDelta = built
      .filter { $0.affectsCash }
      .reduce(0) { $0 + $1.amount }

    let weeksMeta = MoneyCalendar.mondayWeeks(inMonthStarting: monthStart)
    var weekOpening = opening
    var weeks: [MoneyCashFlowWeek] = []
    for meta in weeksMeta {
      let weekStart = cal.startOfDay(for: meta.start)
      let weekEnd = cal.startOfDay(for: meta.end)
      let weekLines = built.filter { $0.date >= weekStart && $0.date < weekEnd }
      let weekIncome = weekLines
        .filter { $0.affectsCash && $0.kind == .income && !$0.isProjected }
        .reduce(0) { $0 + $1.amount }
      let weekExpense = weekLines
        .filter { $0.affectsCash && ($0.kind == .expense || $0.kind == .transfer) && !$0.isProjected && $0.amount < 0 }
        .reduce(0) { $0 + abs($1.amount) }
      let weekProjected = weekLines
        .filter { $0.affectsCash && $0.isProjected && $0.amount < 0 }
        .reduce(0) { $0 + abs($1.amount) }
      let weekProjectedIn = weekLines
        .filter { $0.affectsCash && $0.isProjected && $0.amount > 0 }
        .reduce(0) { $0 + $1.amount }
      let weekDelta = weekLines
        .filter(\.affectsCash)
        .reduce(0) { $0 + $1.amount }
      let weekClosing = weekOpening + weekDelta
      let range = MoneyCalendar.weekRangeLabel(start: weekStart, endExclusive: weekEnd)
      weeks.append(
        MoneyCashFlowWeek(
          id: "\(monthId)-w\(meta.index)",
          index: meta.index,
          title: "Semana \(meta.index)",
          rangeLabel: range,
          start: weekStart,
          end: weekEnd,
          opening: weekOpening,
          lines: weekLines,
          income: weekIncome,
          expense: weekExpense,
          projectedOut: weekProjected,
          projectedIn: weekProjectedIn,
          closing: weekClosing
        )
      )
      weekOpening = weekClosing
    }

    return MoneyCashFlowReport(
      monthId: monthId,
      title: MoneyCalendar.monthTitle(for: monthStart),
      monthStart: monthStart,
      monthEnd: monthEnd,
      opening: opening,
      lines: built,
      weeks: weeks,
      income: income,
      expense: expense,
      transferNet: transferNet,
      projectedOut: projectedOut,
      projectedIn: projectedIn,
      cardPurchases: cardPurchases,
      closingRealized: opening + realizedDelta,
      closingProjected: opening + projectedDelta
    )
  }

  private func liquidOpeningBalance(liquidIds: Set<String>, at monthStart: Date) -> Double {
    guard !liquidIds.isEmpty else { return 0 }
    var balances: [String: Double] = [:]
    for account in accounts where liquidIds.contains(account.id) {
      balances[account.id] = account.balance
    }
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    // Só desfaz o extrato até hoje. Lançamentos futuros (out/nov…) no livro-razão
    // não podem “roubar” o saldo inicial do mês — era isso que inventava o −R$ 6.793.
    for entry in ledger where liquidIds.contains(entry.accountId) {
      let day = cal.startOfDay(for: entry.date)
      guard day >= monthStart, day <= today else { continue }
      if entry.isIncome {
        balances[entry.accountId, default: 0] -= entry.amount
      } else {
        balances[entry.accountId, default: 0] += entry.amount
      }
    }
    return balances.values.reduce(0, +)
  }

  func shiftStatementAnchor(accountId: String, from date: Date, by steps: Int) -> Date {
    guard let account = account(id: accountId) else {
      return MoneyCalendar.shiftMonth(MoneyCalendar.monthStart(for: date), by: steps)
    }
    return MoneyCalendar.shiftStatementAnchor(account: account, from: date, by: steps)
  }

  func canAdvanceStatement(accountId: String, from date: Date) -> Bool {
    guard let account = account(id: accountId) else { return false }
    if !MoneyCalendar.isCurrentOrFuturePeriod(account: account, anchor: date) {
      return true
    }
    let next = shiftStatementAnchor(accountId: accountId, from: date, by: 1)
    let nextPeriod = MoneyCalendar.statementPeriod(for: account, containing: next)
    return ledger.contains { $0.accountId == accountId && $0.date >= nextPeriod.start }
  }

  func account(forSubtaskId id: String?) -> MoneyAccount? {
    guard let id, let link = obligationLinks[id] else { return nil }
    return accounts.first { $0.id == link.accountId }
  }

  func linkedAccountId(forSubtaskId id: String?) -> String? {
    guard let id else { return nil }
    return obligationLinks[id]?.accountId
  }

  func setAccount(forSubtaskId id: String, accountId: String?, valor: Double?) {
    if let accountId {
      obligationLinks[id] = MoneyObligationLink(accountId: accountId, valor: valor ?? 0)
    } else {
      obligationLinks.removeValue(forKey: id)
    }
    persistLinks()
  }

  func updateLinkedValor(subtaskId: String, valor: Double?) {
    guard var link = obligationLinks[subtaskId] else { return }
    if let valor, valor.isFinite {
      link.valor = valor
      obligationLinks[subtaskId] = link
    } else {
      obligationLinks.removeValue(forKey: subtaskId)
    }
    persistLinks()
  }

  /// Concluir desconta (saída) ou soma (entrada) na conta ligada; desfazer reverte o extrato.
  func handleToggleDone(
    subtaskId: String?,
    done: Bool,
    valor: Double?,
    title: String? = nil,
    isIncome: Bool = false
  ) {
    guard let subtaskId else { return }
    let income = isIncome || obligationIsIncome(subtaskId)
    if let link = obligationLinks[subtaskId] {
      let amount = (valor ?? link.valor)
      if amount > 0 {
        if done {
          let alreadyPosted = ledger.contains { $0.subtaskId == subtaskId }
          if !alreadyPosted {
            applyAccountDelta(accountId: link.accountId, amount: amount, reverse: income)
            let due = obligationDueDate(subtaskId) ?? Date()
            appendLedger(
              accountId: link.accountId,
              amount: amount,
              isIncome: income,
              title: title,
              subtaskId: subtaskId,
              date: due
            )
          }
        } else {
          applyAccountDelta(accountId: link.accountId, amount: amount, reverse: !income)
          let removed = ledger.filter { $0.subtaskId == subtaskId }.map(\.id)
          ledger.removeAll { $0.subtaskId == subtaskId }
          persistLedger(deletedIds: removed)
        }
      }
    }
    let tracked = obligationLinks[subtaskId] != nil
      || dueItems.contains { $0.subtask.id == subtaskId || $0.id == subtaskId }
      || receivableItems.contains { $0.subtask.id == subtaskId || $0.id == subtaskId }
      || completedItems.contains { $0.subtask.id == subtaskId || $0.id == subtaskId }
      || completedReceivableItems.contains { $0.subtask.id == subtaskId || $0.id == subtaskId }
    guard tracked else { return }
    if done {
      moveDueItemToCompleted(subtaskId: subtaskId)
    } else {
      moveCompletedItemToDue(subtaskId: subtaskId)
    }
  }

  private func obligationIsIncome(_ subtaskId: String) -> Bool {
    let match: (MoneyDueItem) -> Bool = { $0.subtask.id == subtaskId || $0.id == subtaskId }
    return dueItems.first(where: match)?.isIncome
      ?? receivableItems.first(where: match)?.isIncome
      ?? completedItems.first(where: match)?.isIncome
      ?? completedReceivableItems.first(where: match)?.isIncome
      ?? false
  }

  private func obligationDueDate(_ subtaskId: String) -> Date? {
    let match: (MoneyDueItem) -> Bool = { $0.subtask.id == subtaskId || $0.id == subtaskId }
    let due = dueItems.first(where: match)?.dueDate
      ?? receivableItems.first(where: match)?.dueDate
      ?? completedItems.first(where: match)?.dueDate
      ?? completedReceivableItems.first(where: match)?.dueDate
    return due.map { Calendar.current.startOfDay(for: $0) }
  }

  private func moveDueItemToCompleted(subtaskId: String) {
    if let item = dueItems.first(where: { $0.id == subtaskId || $0.subtask.id == subtaskId }) {
      dueItems.removeAll { $0.id == subtaskId || $0.subtask.id == subtaskId }
      completedItems.removeAll { $0.id == item.id || $0.subtask.id == item.subtask.id }
      completedItems.append(item)
      completedItems.sort(by: Self.sortDue)
      monthItems = dueItems.filter(Self.isInCurrentMonth)
      rebuildDueGroups()
      return
    }
    if let item = receivableItems.first(where: { $0.id == subtaskId || $0.subtask.id == subtaskId }) {
      receivableItems.removeAll { $0.id == subtaskId || $0.subtask.id == subtaskId }
      completedReceivableItems.removeAll { $0.id == item.id || $0.subtask.id == item.subtask.id }
      completedReceivableItems.append(item)
      completedReceivableItems.sort(by: Self.sortDue)
      monthReceivableItems = receivableItems.filter(Self.isInCurrentMonth)
      rebuildDueGroups()
      return
    }
    _Concurrency.Task { await load() }
  }

  private func moveCompletedItemToDue(subtaskId: String) {
    if let item = completedItems.first(where: { $0.id == subtaskId || $0.subtask.id == subtaskId }) {
      completedItems.removeAll { $0.id == subtaskId || $0.subtask.id == subtaskId }
      dueItems.removeAll { $0.id == item.id || $0.subtask.id == item.subtask.id }
      dueItems.append(item)
      dueItems.sort(by: Self.sortDue)
      monthItems = dueItems.filter(Self.isInCurrentMonth)
      rebuildDueGroups()
      return
    }
    if let item = completedReceivableItems.first(where: { $0.id == subtaskId || $0.subtask.id == subtaskId }) {
      completedReceivableItems.removeAll { $0.id == subtaskId || $0.subtask.id == subtaskId }
      receivableItems.removeAll { $0.id == item.id || $0.subtask.id == item.subtask.id }
      receivableItems.append(item)
      receivableItems.sort(by: Self.sortDue)
      monthReceivableItems = receivableItems.filter(Self.isInCurrentMonth)
      rebuildDueGroups()
      return
    }
    _Concurrency.Task { await load() }
  }

  private func rebuildDueGroups() {
    monthGroups = Self.groupedByMonth(pending: dueItems, completed: completedItems)
    dueOutline = Self.outline(from: monthGroups)
    receivableMonthGroups = Self.prefixed(
      Self.groupedByMonth(pending: receivableItems, completed: completedReceivableItems),
      prefix: "recv-"
    )
    receivableOutline = Self.outline(from: receivableMonthGroups)
  }

  private func pendingReceivables(in monthId: String) -> [MoneyDueItem] {
    receivableMonthGroups.first { $0.calendarMonthId == monthId }?.items ?? []
  }

  private func currentAmount(_ account: MoneyAccount) -> Double {
    if account.kind == .credit { return account.invoiceAmount ?? 0 }
    return account.balance
  }

  private func signedAmount(_ entry: MoneyLedgerEntry, account: MoneyAccount) -> Double {
    if account.kind == .credit {
      return entry.isIncome ? -entry.amount : entry.amount
    }
    return entry.isIncome ? entry.amount : -entry.amount
  }

  private func appendLedger(
    accountId: String,
    amount: Double,
    isIncome: Bool,
    title: String?,
    subtaskId: String?,
    date: Date = Date(),
    installmentGroupId: String? = nil,
    installmentIndex: Int? = nil,
    installmentCount: Int? = nil,
    invoiceApplied: Bool = false,
    persist: Bool = true
  ) {
    guard amount > 0 else { return }
    let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let fallback = isIncome ? "Entrada" : "Saída"
    ledger.append(
      MoneyLedgerEntry(
        id: UUID().uuidString,
        accountId: accountId,
        date: date,
        amount: amount,
        isIncome: isIncome,
        title: trimmed.isEmpty ? fallback : trimmed,
        subtaskId: subtaskId,
        installmentGroupId: installmentGroupId,
        installmentIndex: installmentIndex,
        installmentCount: installmentCount,
        invoiceApplied: invoiceApplied
      )
    )
    if persist { persistLedger() }
  }

  private func applyCardInstallment(
    accountId: String,
    total: Double,
    title: String?,
    date: Date,
    count: Int
  ) {
    guard let account = account(id: accountId), account.kind == .credit, count > 1, total > 0 else {
      applyAccountDelta(accountId: accountId, amount: total, reverse: false)
      appendLedger(
        accountId: accountId,
        amount: total,
        isIncome: false,
        title: title,
        subtaskId: nil,
        date: date
      )
      return
    }
    let amounts = MoneyCardInstallment.splitTotal(total, count: count)
    let dates = MoneyCardInstallment.dates(purchase: date, count: count, account: account)
    let groupId = UUID().uuidString
    let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let name = trimmed.isEmpty ? "Compra" : trimmed
    let currentEnd = MoneyCalendar.statementPeriod(for: account, containing: Date()).end
    for index in 0..<count {
      let inOpenInvoice = dates[index] < currentEnd
      appendLedger(
        accountId: accountId,
        amount: amounts[index],
        isIncome: false,
        title: name,
        subtaskId: nil,
        date: dates[index],
        installmentGroupId: groupId,
        installmentIndex: index + 1,
        installmentCount: count,
        invoiceApplied: inOpenInvoice,
        persist: false
      )
      if inOpenInvoice {
        applyAccountDelta(accountId: accountId, amount: amounts[index], reverse: false)
      }
    }
    persistLedger()
  }

  private func replaceCardInstallment(
    entry: MoneyLedgerEntry,
    accountId: String,
    total: Double,
    isIncome: Bool,
    title: String?,
    date: Date,
    count: Int
  ) {
    if let group = entry.installmentGroupId {
      deleteCardInstallment(groupId: group)
    } else {
      deleteLedgerEntry(id: entry.id)
    }
    if isIncome || count <= 1 || account(id: accountId)?.kind != .credit {
      applyMovement(
        accountId: accountId,
        amount: total,
        isIncome: isIncome,
        title: title,
        date: date
      )
      return
    }
    applyCardInstallment(
      accountId: accountId,
      total: total,
      title: title,
      date: date,
      count: count
    )
  }

  private func deleteCardInstallment(groupId: String) {
    let entries = ledger.filter { $0.installmentGroupId == groupId }
    guard !entries.isEmpty else { return }
    for entry in entries where entry.invoiceApplied && !entry.isIncome {
      applyAccountDelta(accountId: entry.accountId, amount: entry.amount, reverse: true)
      clampCreditInvoice(accountId: entry.accountId)
    }
    let ids = entries.map(\.id)
    ledger.removeAll { $0.installmentGroupId == groupId }
    persistLedger(deletedIds: ids)
  }

  private func postInstallmentsToOpenInvoice() {
    var postedIds: [String] = []
    for index in ledger.indices {
      var entry = ledger[index]
      guard entry.isCardInstallment, !entry.isIncome, !entry.invoiceApplied else { continue }
      guard let account = account(id: entry.accountId), account.kind == .credit else { continue }
      let currentEnd = MoneyCalendar.statementPeriod(for: account, containing: Date()).end
      guard entry.date < currentEnd else { continue }
      entry.invoiceApplied = true
      ledger[index] = entry
      applyAccountDelta(accountId: entry.accountId, amount: entry.amount, reverse: false)
      postedIds.append(entry.id)
    }
    if !postedIds.isEmpty {
      persistLedger()
    }
  }

  private func unpostedInstallments(accountId: String) -> [MoneyLedgerEntry] {
    guard let account = account(id: accountId) else { return [] }
    let currentEnd = MoneyCalendar.statementPeriod(for: account, containing: Date()).end
    return ledger.filter { entry in
      entry.accountId == accountId
        && entry.isCardInstallment
        && !entry.isIncome
        && entry.date >= currentEnd
    }
  }

  private func isPostedToOpenInvoice(
    _ entry: MoneyLedgerEntry,
    account: MoneyAccount,
    currentEnd: Date
  ) -> Bool {
    if entry.isCardInstallment {
      return entry.invoiceApplied || entry.date < currentEnd
    }
    return entry.date < currentEnd
  }

  private func clampCreditInvoice(accountId: String) {
    guard let index = accounts.firstIndex(where: { $0.id == accountId }) else { return }
    var account = accounts[index]
    guard account.kind == .credit else { return }
    let value = account.invoiceAmount ?? 0
    if value < 0 {
      account.invoiceAmount = 0
      accounts[index] = account
      persistAccounts()
    }
  }

  private func applyAccountDelta(accountId: String, amount: Double, reverse: Bool) {
    guard amount > 0, let index = accounts.firstIndex(where: { $0.id == accountId }) else { return }
    let signed = reverse ? -amount : amount
    var account = accounts[index]
    if account.kind == .credit {
      account.invoiceAmount = (account.invoiceAmount ?? 0) + signed
    } else {
      account.balance -= signed
    }
    accounts[index] = account
    persistAccounts()
  }

  private func hydrateAccounts() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      accounts = []
      return
    }
    guard let data = UserDefaults.standard.data(forKey: Self.accountsKey(userId)),
          let decoded = try? JSONDecoder().decode([MoneyAccount].self, from: data)
    else {
      if accounts.isEmpty { accounts = [] }
      return
    }
    accounts = decoded
  }

  private func persistAccounts() {
    persistAccountsCache()
    let snapshot = accounts
    _Concurrency.Task { @MainActor in
      do {
        try await MoneyRepository.upsertAccounts(snapshot)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  private func persistAccountsCache() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else { return }
    guard let data = try? JSONEncoder().encode(accounts) else { return }
    UserDefaults.standard.set(data, forKey: Self.accountsKey(userId))
  }

  private func hydrateLinks() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      obligationLinks = [:]
      return
    }
    guard let data = UserDefaults.standard.data(forKey: Self.linksKey(userId)),
          let decoded = try? JSONDecoder().decode([String: MoneyObligationLink].self, from: data)
    else {
      obligationLinks = [:]
      return
    }
    obligationLinks = decoded
  }

  private func persistLinks() {
    persistLinksCache()
    let snapshot = obligationLinks
    _Concurrency.Task { @MainActor in
      do {
        try await MoneyRepository.upsertLinks(snapshot)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  private func persistLinksCache() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else { return }
    guard let data = try? JSONEncoder().encode(obligationLinks) else { return }
    UserDefaults.standard.set(data, forKey: Self.linksKey(userId))
  }

  private func hydrateLedger() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      ledger = []
      return
    }
    guard let data = UserDefaults.standard.data(forKey: Self.ledgerKey(userId)),
          let decoded = try? JSONDecoder().decode([MoneyLedgerEntry].self, from: data)
    else {
      ledger = []
      return
    }
    ledger = decoded
  }

  private func persistLedger(deletedIds: [String] = []) {
    persistLedgerCache()
    let snapshot = ledger
    let removed = deletedIds
    _Concurrency.Task { @MainActor in
      do {
        if !removed.isEmpty {
          try await MoneyRepository.deleteLedger(ids: removed)
        }
        try await MoneyRepository.upsertLedger(snapshot)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  private func persistLedgerCache() {
    guard let userId = SupabaseService.client.auth.currentUser?.id else { return }
    guard let data = try? JSONEncoder().encode(ledger) else { return }
    UserDefaults.standard.set(data, forKey: Self.ledgerKey(userId))
  }

  private func mergeRemoteMoney() async {
    do {
      // Remoto primeiro — cache local (UserDefaults) é por aparelho; empurrar local
      // antes do fetch sobrescrevia Supabase com snapshot velho do simulador.
      let remote = try await MoneyRepository.fetchSnapshot()

      let remoteAccountIds = Set(remote.accounts.map(\.id))
      let localOnlyAccounts = accounts.filter { !remoteAccountIds.contains($0.id) }
      accounts = remote.accounts + localOnlyAccounts

      let remoteLedgerIds = Set(remote.ledger.map(\.id))
      let localOnlyLedger = ledger.filter { !remoteLedgerIds.contains($0.id) }
      ledger = (remote.ledger + localOnlyLedger).sorted { $0.date < $1.date }

      var mergedLinks = remote.links
      for (id, link) in obligationLinks where mergedLinks[id] == nil {
        mergedLinks[id] = link
      }
      let localOnlyLinks = mergedLinks.filter { remote.links[$0.key] == nil }
      obligationLinks = mergedLinks

      if !localOnlyAccounts.isEmpty {
        try await MoneyRepository.upsertAccounts(localOnlyAccounts)
      }
      if !localOnlyLedger.isEmpty {
        try await MoneyRepository.upsertLedger(localOnlyLedger)
      }
      if !localOnlyLinks.isEmpty {
        try await MoneyRepository.upsertLinks(localOnlyLinks)
      }

      persistAccountsCache()
      persistLinksCache()
      persistLedgerCache()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private static func accountsKey(_ userId: UUID) -> String {
    accountsKeyPrefix + userId.uuidString
  }

  private static func linksKey(_ userId: UUID) -> String {
    linksKeyPrefix + userId.uuidString
  }

  private static func ledgerKey(_ userId: UUID) -> String {
    ledgerKeyPrefix + userId.uuidString
  }

  private static func dueItem(from entry: SubtaskScheduleEntry) -> MoneyDueItem? {
    // Mesmo flag do detalhe: fora do fluxo = fora de A PAGAR (pai e subtarefa).
    guard entry.parent.includeInCashFlow, entry.subtask.includeInCashFlow else { return nil }
    guard let valor = entry.subtask.valor, valor.isFinite else { return nil }
    let due = entry.subtask.dueDate
    let dueLabel: String
    if let due {
      dueLabel = TaskMapper.dayLabel(for: due)
    } else {
      dueLabel = "Sem data"
    }
    return MoneyDueItem(
      id: entry.id,
      title: entry.subtask.title,
      valor: valor,
      dueDate: due,
      dueLabel: dueLabel,
      projectName: entry.parent.project,
      parent: entry.parent,
      subtask: entry.subtask,
      isIncome: entry.subtask.isIncome
    )
  }

  private static func sortDue(_ a: MoneyDueItem, _ b: MoneyDueItem) -> Bool {
    switch (a.dueDate, b.dueDate) {
    case let (l?, r?):
      if l != r { return l < r }
      return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    case (_?, nil):
      return true
    case (nil, _?):
      return false
    case (nil, nil):
      return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }
  }

  /// Vence neste mês de calendário e ainda está em aberto.
  private static func isInCurrentMonth(_ item: MoneyDueItem) -> Bool {
    guard let due = item.dueDate else { return false }
    return MoneyCalendar.monthId(for: due) == MoneyCalendar.monthId(for: Date())
  }

  private static func monthId(for date: Date) -> String {
    MoneyCalendar.monthId(for: date)
  }

  private static func groupedByMonth(
    pending: [MoneyDueItem],
    completed: [MoneyDueItem]
  ) -> [MoneyMonthGroup] {
    let pendingBuckets = monthBuckets(from: pending)
    let completedBuckets = monthBuckets(from: completed)
    var ids = Array(Set(pendingBuckets.keys).union(completedBuckets.keys))
    ids.sort { lhs, rhs in
      if lhs == "undated" { return false }
      if rhs == "undated" { return true }
      return lhs < rhs
    }
    let currentId = MoneyCalendar.monthId(for: Date())
    return ids.compactMap { id in
      let pendingItems = pendingBuckets[id]?.items ?? []
      let doneItems = completedBuckets[id]?.items ?? []
      let isCurrent = id == currentId
      guard !pendingItems.isEmpty || (isCurrent && !doneItems.isEmpty) else { return nil }
      let meta = pendingBuckets[id] ?? completedBuckets[id]
      return MoneyMonthGroup(
        id: id,
        title: meta?.title ?? id,
        year: meta?.year,
        items: pendingItems,
        completedItems: doneItems
      )
    }
  }

  private static func prefixed(_ groups: [MoneyMonthGroup], prefix: String) -> [MoneyMonthGroup] {
    groups.map {
      MoneyMonthGroup(
        id: prefix + $0.id,
        title: $0.title,
        year: $0.year,
        items: $0.items,
        completedItems: $0.completedItems
      )
    }
  }

  private static func monthBuckets(
    from items: [MoneyDueItem]
  ) -> [String: (title: String, year: Int?, items: [MoneyDueItem])] {
    let cal = Calendar.current
    var buckets: [String: (title: String, year: Int?, items: [MoneyDueItem])] = [:]
    for item in items {
      let id: String
      let title: String
      let year: Int?
      if let due = item.dueDate {
        id = MoneyCalendar.monthId(for: due)
        year = cal.component(.year, from: due)
        let month = cal.component(.month, from: due)
        title = MoneyCalendar.monthNames[max(0, min(MoneyCalendar.monthNames.count - 1, month - 1))]
      } else {
        id = "undated"
        year = nil
        title = "Sem data"
      }
      if var existing = buckets[id] {
        existing.items.append(item)
        buckets[id] = existing
      } else {
        buckets[id] = (title, year, [item])
      }
    }
    return buckets
  }

  private static func outline(from months: [MoneyMonthGroup]) -> [MoneyDueOutline] {
    var byYear: [Int: [MoneyMonthGroup]] = [:]
    var undated: MoneyMonthGroup?

    for group in months {
      if group.calendarMonthId == "undated" {
        undated = group
      } else if let year = group.year {
        byYear[year, default: []].append(group)
      }
    }

    var result: [MoneyDueOutline] = []
    for year in byYear.keys.sorted() {
      result.append(.year(year: year, months: byYear[year] ?? []))
    }
    if let undated {
      result.append(.month(undated))
    }
    return result
  }

  private static func installmentGroups(from entries: [SubtaskScheduleEntry]) -> [MoneyInstallmentGroup] {
    let grouped = Dictionary(grouping: entries, by: \.parent.id)
    return grouped.compactMap { parentId, items -> MoneyInstallmentGroup? in
      guard let first = items.first else { return nil }
      let subs = items.map(\.subtask)
      guard let snapshot = InstallmentProgress.snapshot(from: subs) else { return nil }
      let title = first.parent.title.trimmingCharacters(in: .whitespacesAndNewlines)
      return MoneyInstallmentGroup(
        id: parentId,
        title: title.isEmpty ? "Parcelas" : title,
        snapshot: snapshot
      )
    }
    .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }
}

private extension String {
  var moneyNilIfEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
