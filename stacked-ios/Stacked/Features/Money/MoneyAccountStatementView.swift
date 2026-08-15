import SwiftUI
import Hugeicons

struct MoneyAccountStatementView: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = MoneyStore.shared
  @State private var periodAnchor = Date()
  @State private var editingAccount: MoneyAccount?
  @State private var movementSheet: MovementSheetMode?
  @State private var pendingDeleteEntry: MoneyLedgerEntry?
  @State private var payError: String?

  let accountId: String

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private var account: MoneyAccount? {
    store.account(id: accountId)
  }

  private var statement: MoneyMonthStatement? {
    store.statement(accountId: accountId, monthStart: periodAnchor)
  }

  private var canGoForward: Bool {
    store.canAdvanceStatement(accountId: accountId, from: periodAnchor)
  }

  private var isCurrentPeriod: Bool {
    guard let account else { return true }
    let viewing = MoneyCalendar.statementPeriod(for: account, containing: periodAnchor)
    let current = MoneyCalendar.statementPeriod(for: account, containing: Date())
    return viewing.start == current.start
  }

  var body: some View {
    let c = theme.colors
    List {
      monthPager
      if statement?.usesInvoiceCycle == true {
        invoiceHero
      } else {
        summaryCard
      }
      if let account, account.kind == .credit, isCurrentPeriod {
        payInvoiceRow(account)
      }
      movementsSection
      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .listSectionSpacing(16)
    .scrollContentBackground(.hidden)
    .stackedDashboardListChrome()
    .stackedTabletCentered()
    .stackedThemeBackground(theme)
    .navigationTitle(account?.name ?? "Extrato")
    .navigationBarTitleDisplayMode(.inline)
    .stackedAdaptiveDrillDownBack()
    .toolbar {
      let isolate = GlassChromePreference.prefersStaticToolbarPills()
      ToolbarItem(id: "stacked-statement-edit", placement: .topBarTrailing) {
        StackedToolbarIconButton(icon: .edit, accessibilityLabel: "Editar conta") {
          editingAccount = account
        }
      }
      .stackedToolbarGlassIsolation(isolate)
      ToolbarItem(id: "stacked-statement-pdf", placement: .topBarTrailing) {
        StackedToolbarTextButton(title: "PDF", accent: true) {
          exportPDF()
        }
      }
      .stackedToolbarGlassIsolation(isolate)
    }
    .sheet(item: $editingAccount) { item in
      MoneyAccountSheet(account: item) { saved in
        store.updateAccount(saved)
      }
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .stackedEditableSheetPresentation(background: c.background)
    }
    .sheet(item: $movementSheet) { mode in
      MoneyMovementSheet(
        accounts: store.accounts,
        initialAccountId: accountId,
        startsAsTransfer: mode.startsAsTransfer,
        editing: mode.editing,
        onSave: { id, amount, isIncome, title, date, installments in
          store.applyMovement(
            accountId: id,
            amount: amount,
            isIncome: isIncome,
            title: title,
            date: date,
            installmentCount: installments
          )
        },
        onTransfer: { fromId, toId, amount, title, date in
          _ = store.transfer(fromAccountId: fromId, toAccountId: toId, amount: amount, title: title, date: date)
        },
        onUpdate: { id, accountId, amount, isIncome, title, date, installments in
          store.updateLedgerEntry(
            id: id,
            accountId: accountId,
            amount: amount,
            isIncome: isIncome,
            title: title,
            date: date,
            installmentCount: installments
          )
        }
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .stackedEditableSheetPresentation(background: c.background)
    }
    .alert("Não foi possível pagar", isPresented: Binding(
      get: { payError != nil },
      set: { if !$0 { payError = nil } }
    )) {
      Button("OK", role: .cancel) { payError = nil }
    } message: {
      Text(payError ?? "")
    }
    .alert(
      "Excluir lançamento?",
      isPresented: Binding(
        get: { pendingDeleteEntry != nil },
        set: { if !$0 { pendingDeleteEntry = nil } }
      )
    ) {
      Button("Excluir", role: .destructive) {
        if let id = pendingDeleteEntry?.id {
          store.deleteLedgerEntry(id: id)
        }
        pendingDeleteEntry = nil
      }
      Button("Cancelar", role: .cancel) { pendingDeleteEntry = nil }
    } message: {
      if pendingDeleteEntry?.isCardInstallment == true {
        let n = pendingDeleteEntry?.installmentCount ?? 0
        Text("Exclui as \(n) parcelas deste plano. A fatura aberta é ajustada.")
      } else if account?.kind == .credit {
        Text("O valor some do extrato e a fatura é ajustada.")
      } else {
        Text("O valor some do extrato e o saldo é ajustado.")
      }
    }
  }

  private var monthPager: some View {
    let c = theme.colors
    return Section {
      VStack(spacing: 4) {
        HStack {
          Button {
            HapticService.selection()
            periodAnchor = store.shiftStatementAnchor(accountId: accountId, from: periodAnchor, by: -1)
          } label: {
            StackedIcons.image(.arrowLeft)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(c.textPrimary)
              .frame(width: 36, height: 36)
          }
          .buttonStyle(.plain)
          Spacer()
          Text(statement?.periodTitle ?? MoneyCalendar.monthTitle(for: periodAnchor))
            .font(typeScale.metrics.rowTitleFont)
            .foregroundStyle(c.textPrimary)
          Spacer()
          Button {
            guard canGoForward else { return }
            HapticService.selection()
            periodAnchor = store.shiftStatementAnchor(accountId: accountId, from: periodAnchor, by: 1)
          } label: {
            StackedIcons.image(.chevronRight)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(canGoForward ? c.textPrimary : c.textTertiary)
              .frame(width: 36, height: 36)
          }
          .buttonStyle(.plain)
          .disabled(!canGoForward)
        }
        if let caption = statement?.periodCaption {
          Text(caption)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
        }
      }
      .padding(.vertical, 4)
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  private var invoiceHero: some View {
    let c = theme.colors
    let snap = statement
    let isCurrent = isCurrentPeriod
    return Section {
      VStack(alignment: .leading, spacing: 4) {
        Text(isCurrent ? "Fatura aberta" : "Fatura")
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(c.textTertiary)
        Text(CurrencyFormat.brl(snap?.closing ?? 0))
          .font(typeScale.metrics.rowTitleFont)
          .fontWeight(.semibold)
          .monospacedDigit()
          .foregroundStyle(c.accent)
        let bits = [snap?.periodCaption, snap?.dueCaption].compactMap { $0 }
        if !bits.isEmpty {
          Text(bits.joined(separator: " · "))
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(style: sectionStyle, position: .only, colors: c)
      )
    }
  }

  private var summaryCard: some View {
    let c = theme.colors
    let snap = statement
    return Section {
      VStack(spacing: 0) {
        summaryLine("\(snap?.amountLabel ?? "Saldo") inicial", snap?.opening ?? 0, accent: false)
        SettingsCardDivider(leadingPadding: 14)
        summaryLine("Entradas", snap?.income ?? 0, accent: true, prefix: "+")
        SettingsCardDivider(leadingPadding: 14)
        summaryLine("Saídas", snap?.expense ?? 0, accent: false, prefix: "−")
        SettingsCardDivider(leadingPadding: 14)
        summaryLine("\(snap?.amountLabel ?? "Saldo") final", snap?.closing ?? 0, accent: true, bold: true)
      }
      .padding(.vertical, 4)
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(style: sectionStyle, position: .only, colors: c)
      )
    }
  }

  private func summaryLine(_ title: String, _ amount: Double, accent: Bool, prefix: String = "", bold: Bool = false) -> some View {
    let c = theme.colors
    return HStack {
      Text(title)
        .font(AppTypography.settingsTitle)
        .foregroundStyle(c.textSecondary)
      Spacer()
      Text("\(prefix)\(CurrencyFormat.brl(amount))")
        .font(bold ? AppTypography.bodySemibold : AppTypography.body)
        .monospacedDigit()
        .foregroundStyle(accent ? c.accent : c.textPrimary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  private func payInvoiceRow(_ account: MoneyAccount) -> some View {
    let c = theme.colors
    let amount = account.invoiceAmount ?? 0
    let parentName = account.parentAccountId.flatMap { store.account(id: $0)?.name }
    return Section {
      Button {
        HapticService.selection()
        if let error = store.payInvoice(cardId: account.id) {
          payError = error
        } else {
          HapticService.saved()
        }
      } label: {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Pagar fatura")
              .font(typeScale.metrics.rowTitleFont)
              .foregroundStyle(c.textPrimary)
            Text(parentName.map { "Desconta de \($0)" } ?? "Ligue o cartão a um banco para pagar")
              .font(AppTypography.screenSubtitle)
              .foregroundStyle(c.textTertiary)
          }
          Spacer()
          Text(CurrencyFormat.brl(amount))
            .font(typeScale.metrics.rowCountFont)
            .monospacedDigit()
            .foregroundStyle(c.accent)
        }
        .padding(.vertical, sectionStyle.metrics.rowPaddingV)
      }
      .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
      .disabled(amount <= 0 || parentName == nil)
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(style: sectionStyle, position: .only, colors: c)
      )
    }
  }

  private var canTransfer: Bool {
    account?.kind != .credit && store.transferableAccounts().count >= 2
  }

  @ViewBuilder
  private var movementsSection: some View {
    let c = theme.colors
    let lines = statement?.lines ?? []
    let extra = canTransfer ? 2 : 1
    let hintCount = lines.isEmpty ? 1 : 0
    let total = hintCount + lines.count + extra
    Section {
      if lines.isEmpty {
        Text(
          account?.kind == .credit
            ? (statement?.usesInvoiceCycle == true
              ? "Nenhum lançamento nesta fatura."
              : "Nenhum lançamento neste mês. Entradas, saídas e compras no cartão aparecem aqui.")
            : "Nenhum lançamento neste mês. Entradas, saídas e transferências aparecem aqui."
        )
          .font(typeScale.metrics.rowTitleFont)
          .foregroundStyle(c.textTertiary)
          .padding(.vertical, sectionStyle.metrics.rowPaddingV)
          .listRowInsets(sectionStyle.metrics.rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(
            HomeSectionRowBackground(style: sectionStyle, position: .at(index: 0, count: total), colors: c)
          )
      } else {
        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
          SubtaskTitlePressArea(
            onTap: {
              openEdit(for: line)
            },
            onDelete: {
              pendingDeleteEntry = store.ledgerEntry(id: line.id)
            },
            deleteLabel: "Excluir lançamento",
            extraItems: [
              PopoverMenuItem(
                id: "edit",
                icon: Hugeicons.edit01,
                label: "Editar"
              )
            ],
            onMenuResult: { result in
              if result == "edit" {
                openEdit(for: line)
              }
            }
          ) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
              Text(line.dayLabel)
                .font(AppTypography.meta)
                .foregroundStyle(c.textTertiary)
                .frame(width: 52, alignment: .leading)
              VStack(alignment: .leading, spacing: 2) {
                Text(line.title)
                  .font(typeScale.metrics.rowTitleFont)
                  .foregroundStyle(c.textPrimary)
                  .lineLimit(1)
                Text(lineKindLabel(line))
                  .font(AppTypography.screenSubtitle)
                  .foregroundStyle(c.textTertiary)
              }
              Spacer(minLength: 8)
              Text("\(line.isIncome ? "+" : "−")\(CurrencyFormat.brl(line.amount))")
                .font(typeScale.metrics.rowCountFont)
                .monospacedDigit()
                .foregroundStyle(line.isIncome ? c.accent : c.textPrimary)
                .fixedSize()
            }
            .padding(.vertical, sectionStyle.metrics.rowPaddingV)
            .contentShape(Rectangle())
          }
          .listRowInsets(sectionStyle.metrics.rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(
            HomeSectionRowBackground(
              style: sectionStyle,
              position: .at(index: index, count: total),
              colors: c
            )
          )
        }
      }
      Button {
        HapticService.selection()
        movementSheet = .create(transfer: false)
      } label: {
        HStack(spacing: HomeSectionRowLayout.iconSpacing) {
          StackedIcons.image(.plus)
            .font(.system(size: 18))
            .foregroundStyle(c.accent)
            .frame(width: HomeSectionRowLayout.iconWidth)
          Text(account?.kind == .credit ? "Nova compra" : "Novo lançamento")
            .font(typeScale.metrics.rowTitleFont)
            .foregroundStyle(c.textPrimary)
          Spacer()
        }
        .padding(.vertical, sectionStyle.metrics.rowPaddingV)
      }
      .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(
          style: sectionStyle,
          position: .at(index: hintCount + lines.count, count: total),
          colors: c
        )
      )
      if canTransfer {
        Button {
          HapticService.selection()
          movementSheet = .create(transfer: true)
        } label: {
          HStack(spacing: HomeSectionRowLayout.iconSpacing) {
            StackedIcons.image(Hugeicons.arrowDataTransferHorizontal)
              .font(.system(size: 18))
              .foregroundStyle(c.accent)
              .frame(width: HomeSectionRowLayout.iconWidth)
            Text("Transferir")
              .font(typeScale.metrics.rowTitleFont)
              .foregroundStyle(c.textPrimary)
            Spacer()
          }
          .padding(.vertical, sectionStyle.metrics.rowPaddingV)
        }
        .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
        .listRowInsets(sectionStyle.metrics.rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(
          HomeSectionRowBackground(
            style: sectionStyle,
            position: .at(index: hintCount + lines.count + 1, count: total),
            colors: c
          )
        )
      }
    } header: {
      HomeSectionHeader(
        text: statement?.usesInvoiceCycle == true ? "NESTA FATURA" : "LANÇAMENTOS",
        style: sectionStyle,
        scale: typeScale
      )
        .homeSectionHeaderInsets(sectionStyle)
    }

    if let statement, statement.usesInvoiceCycle, isCurrentPeriod {
      let close = Calendar.current.date(byAdding: .day, value: -1, to: statement.periodEnd) ?? statement.periodEnd
      Section {
        Text("Compra depois de \(MoneyCalendar.dayLabel(for: close)) entra na próxima fatura.")
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 2)
          .listRowInsets(sectionStyle.metrics.rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
  }

  private func openEdit(for line: MoneyStatementLine) {
    guard let entry = store.ledgerEntry(id: line.id) else { return }
    HapticService.selection()
    movementSheet = .edit(entry)
  }

  private func lineKindLabel(_ line: MoneyStatementLine) -> String {
    if let caption = line.caption { return caption }
    if line.title.localizedCaseInsensitiveContains("transferência") {
      return "Transferência"
    }
    if account?.kind == .credit {
      return line.isIncome ? "Pagamento" : "Compra"
    }
    return line.isIncome ? "Entrada" : "Saída"
  }

  private func exportPDF() {
    guard let statement else { return }
    HapticService.selection()
    if let url = MoneyStatementPDF.fileURL(for: statement) {
      MoneySharePresenter.present(url)
    }
  }
}

private enum MovementSheetMode: Identifiable {
  case create(transfer: Bool)
  case edit(MoneyLedgerEntry)

  var id: String {
    switch self {
    case .create(let transfer):
      return transfer ? "create-transfer" : "create"
    case .edit(let entry):
      return "edit-\(entry.id)"
    }
  }

  var startsAsTransfer: Bool {
    if case .create(let transfer) = self { return transfer }
    return false
  }

  var editing: MoneyLedgerEntry? {
    if case .edit(let entry) = self { return entry }
    return nil
  }
}
