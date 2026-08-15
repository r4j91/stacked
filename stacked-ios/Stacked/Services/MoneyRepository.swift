import Foundation
import Supabase

@MainActor
enum MoneyRepository {
  private static var client: SupabaseClient { SupabaseService.client }

  struct Snapshot {
    var accounts: [MoneyAccount]
    var ledger: [MoneyLedgerEntry]
    var links: [String: MoneyObligationLink]
  }

  static func fetchSnapshot() async throws -> Snapshot {
    async let accountsReq: [MoneyAccountRow] = client
      .from("money_accounts")
      .select("id, name, kind, balance, due_day, closing_day, invoice_amount, parent_account_id")
      .order("name")
      .execute()
      .value
    async let ledgerReq: [MoneyLedgerRow] = client
      .from("money_ledger")
      .select("id, account_id, occurred_at, amount, is_income, title, subtask_id, installment_group_id, installment_index, installment_count, invoice_applied")
      .order("occurred_at")
      .execute()
      .value
    async let linksReq: [MoneyLinkRow] = client
      .from("money_obligation_links")
      .select("subtask_id, account_id, valor")
      .execute()
      .value
    let rows = try await accountsReq
    let ledgerRows = try await ledgerReq
    let linkRows = try await linksReq
    var links: [String: MoneyObligationLink] = [:]
    for row in linkRows {
      links[row.subtask_id] = MoneyObligationLink(accountId: row.account_id, valor: row.valor)
    }
    return Snapshot(
      accounts: rows.map(\.asAccount),
      ledger: ledgerRows.map(\.asEntry),
      links: links
    )
  }

  static func upsertAccounts(_ accounts: [MoneyAccount]) async throws {
    guard !accounts.isEmpty else { return }
    let userId = try await requireUserId()
    let banks = accounts.filter { $0.kind != .credit }.compactMap { MoneyAccountUpsert($0, userId: userId) }
    let cards = accounts.filter { $0.kind == .credit }.compactMap { MoneyAccountUpsert($0, userId: userId) }
    try await NetLog.timed("money.accounts.upsert", step: .insertTask) {
      if !banks.isEmpty {
        try await client.from("money_accounts").upsert(banks, onConflict: "id").execute()
      }
      if !cards.isEmpty {
        try await client.from("money_accounts").upsert(cards, onConflict: "id").execute()
      }
    }
  }

  static func deleteAccounts(ids: [String]) async throws {
    guard !ids.isEmpty else { return }
    try await client.from("money_accounts").delete().in("id", values: ids).execute()
  }

  static func upsertLedger(_ entries: [MoneyLedgerEntry]) async throws {
    guard !entries.isEmpty else { return }
    let userId = try await requireUserId()
    let rows = entries.compactMap { MoneyLedgerUpsert($0, userId: userId) }
    guard !rows.isEmpty else { return }
    try await NetLog.timed("money.ledger.upsert", step: .insertTask) {
      try await client.from("money_ledger").upsert(rows, onConflict: "id").execute()
    }
  }

  static func deleteLedger(ids: [String]) async throws {
    guard !ids.isEmpty else { return }
    try await client.from("money_ledger").delete().in("id", values: ids).execute()
  }

  static func upsertLinks(_ links: [String: MoneyObligationLink]) async throws {
    guard !links.isEmpty else { return }
    let userId = try await requireUserId()
    let rows = links.compactMap { subtaskId, link -> MoneyLinkUpsert? in
      guard UUID(uuidString: link.accountId) != nil else { return nil }
      return MoneyLinkUpsert(
        subtask_id: subtaskId,
        user_id: userId.uuidString,
        account_id: link.accountId,
        valor: link.valor
      )
    }
    guard !rows.isEmpty else { return }
    try await NetLog.timed("money.links.upsert", step: .insertTask) {
      try await client.from("money_obligation_links").upsert(rows, onConflict: "subtask_id").execute()
    }
  }

  static func deleteLinks(subtaskIds: [String]) async throws {
    guard !subtaskIds.isEmpty else { return }
    try await client.from("money_obligation_links").delete().in("subtask_id", values: subtaskIds).execute()
  }

  private static func requireUserId() async throws -> UUID {
    if let id = client.auth.currentUser?.id { return id }
    return try await client.auth.session.user.id
  }
}

private struct MoneyAccountUpsert: Encodable {
  let id: String
  let user_id: String
  let name: String
  let kind: String
  let balance: Double
  let due_day: Int?
  let closing_day: Int?
  let invoice_amount: Double?
  let parent_account_id: String?

  init?(_ account: MoneyAccount, userId: UUID) {
    guard UUID(uuidString: account.id) != nil else { return nil }
    id = account.id
    user_id = userId.uuidString
    name = account.name
    kind = account.kind.rawValue
    balance = account.balance
    due_day = account.dueDay
    closing_day = account.closingDay
    invoice_amount = account.invoiceAmount
    if let parent = account.parentAccountId, UUID(uuidString: parent) != nil {
      parent_account_id = parent
    } else {
      parent_account_id = nil
    }
  }
}

private struct MoneyLedgerUpsert: Encodable {
  let id: String
  let user_id: String
  let account_id: String
  let occurred_at: String
  let amount: Double
  let is_income: Bool
  let title: String
  let subtask_id: String?
  let installment_group_id: String?
  let installment_index: Int?
  let installment_count: Int?
  let invoice_applied: Bool

  init?(_ entry: MoneyLedgerEntry, userId: UUID) {
    guard UUID(uuidString: entry.id) != nil, UUID(uuidString: entry.accountId) != nil else { return nil }
    id = entry.id
    user_id = userId.uuidString
    account_id = entry.accountId
    occurred_at = TaskMapper.isoTimestamp(entry.date)
    amount = entry.amount
    is_income = entry.isIncome
    title = entry.title
    subtask_id = entry.subtaskId
    if let group = entry.installmentGroupId, UUID(uuidString: group) != nil {
      installment_group_id = group
    } else {
      installment_group_id = nil
    }
    installment_index = entry.installmentIndex
    installment_count = entry.installmentCount
    invoice_applied = entry.invoiceApplied
  }
}

private struct MoneyLinkUpsert: Encodable {
  let subtask_id: String
  let user_id: String
  let account_id: String
  let valor: Double
}

private struct MoneyAccountRow: Decodable {
  let id: String
  let name: String
  let kind: String
  let balance: Double
  let due_day: Int?
  let closing_day: Int?
  let invoice_amount: Double?
  let parent_account_id: String?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = Self.stringId(c, .id) ?? UUID().uuidString
    name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
    kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? MoneyAccount.Kind.checking.rawValue
    balance = InstallmentGeneratorLogic.decodeValor(c, forKey: .balance) ?? 0
    due_day = try c.decodeIfPresent(Int.self, forKey: .due_day)
    closing_day = try c.decodeIfPresent(Int.self, forKey: .closing_day)
    invoice_amount = InstallmentGeneratorLogic.decodeValor(c, forKey: .invoice_amount)
    parent_account_id = Self.stringId(c, .parent_account_id)
  }

  var asAccount: MoneyAccount {
    MoneyAccount(
      id: id,
      name: name,
      kind: MoneyAccount.Kind(rawValue: kind) ?? .checking,
      balance: balance,
      dueDay: due_day,
      closingDay: closing_day,
      invoiceAmount: invoice_amount,
      parentAccountId: parent_account_id
    )
  }

  private static func stringId(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
    if let s = try? c.decodeIfPresent(String.self, forKey: key), !s.isEmpty { return s }
    if let u = try? c.decodeIfPresent(UUID.self, forKey: key) { return u.uuidString }
    return nil
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, kind, balance, due_day, closing_day, invoice_amount, parent_account_id
  }
}

private struct MoneyLedgerRow: Decodable {
  let id: String
  let account_id: String
  let occurred_at: String?
  let amount: Double
  let is_income: Bool
  let title: String
  let subtask_id: String?
  let installment_group_id: String?
  let installment_index: Int?
  let installment_count: Int?
  let invoice_applied: Bool

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = Self.stringId(c, .id) ?? UUID().uuidString
    account_id = Self.stringId(c, .account_id) ?? ""
    occurred_at = try c.decodeIfPresent(String.self, forKey: .occurred_at)
    amount = InstallmentGeneratorLogic.decodeValor(c, forKey: .amount) ?? 0
    is_income = try c.decodeIfPresent(Bool.self, forKey: .is_income) ?? false
    title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    subtask_id = try c.decodeIfPresent(String.self, forKey: .subtask_id)
    installment_group_id = Self.stringId(c, .installment_group_id)
    installment_index = try c.decodeIfPresent(Int.self, forKey: .installment_index)
    installment_count = try c.decodeIfPresent(Int.self, forKey: .installment_count)
    invoice_applied = try c.decodeIfPresent(Bool.self, forKey: .invoice_applied) ?? false
  }

  var asEntry: MoneyLedgerEntry {
    MoneyLedgerEntry(
      id: id,
      accountId: account_id,
      date: TaskMapper.parseCompletionTimestamp(occurred_at) ?? Date(),
      amount: amount,
      isIncome: is_income,
      title: title,
      subtaskId: subtask_id,
      installmentGroupId: installment_group_id,
      installmentIndex: installment_index,
      installmentCount: installment_count,
      invoiceApplied: invoice_applied
    )
  }

  private static func stringId(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
    if let s = try? c.decodeIfPresent(String.self, forKey: key), !s.isEmpty { return s }
    if let u = try? c.decodeIfPresent(UUID.self, forKey: key) { return u.uuidString }
    return nil
  }

  private enum CodingKeys: String, CodingKey {
    case id, account_id, occurred_at, amount, is_income, title, subtask_id
    case installment_group_id, installment_index, installment_count, invoice_applied
  }
}

private struct MoneyLinkRow: Decodable {
  let subtask_id: String
  let account_id: String
  let valor: Double

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .subtask_id) {
      subtask_id = s
    } else {
      subtask_id = try c.decode(UUID.self, forKey: .subtask_id).uuidString
    }
    if let s = try? c.decode(String.self, forKey: .account_id) {
      account_id = s
    } else {
      account_id = try c.decode(UUID.self, forKey: .account_id).uuidString
    }
    valor = InstallmentGeneratorLogic.decodeValor(c, forKey: .valor) ?? 0
  }

  private enum CodingKeys: String, CodingKey {
    case subtask_id, account_id, valor
  }
}
