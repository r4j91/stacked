import SwiftUI
import UIKit
import Hugeicons

struct MoneyView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var store = MoneyStore.shared
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var showMovement = false
  @State private var editingAccount: MoneyAccount?
  @State private var statementRoute: MoneyStatementRoute?
  @State private var cashFlowRoute: MoneyCashFlowRoute?
  @State private var accountPendingDelete: MoneyAccount?
  @State private var expandedMonthIds: Set<String> = []
  @State private var mountedMonthIds: Set<String> = []
  @State private var snapOpenIds: Set<String> = []
  @State private var didSeedExpandedMonths = false
  @State private var searchText = ""
  @Namespace private var taskDetailZoom

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  @AppStorage(MoneyPremiumAppearanceStorage.key) private var moneyPremium = MoneyPremiumAppearanceStorage.defaultEnabled
  @AppStorage(MoneyProposedAppearanceStorage.key) private var moneyProposed = MoneyProposedAppearanceStorage.defaultEnabled
  @State private var scrollToSection: String?
  @State private var searchBarCompact = false

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private var isMoneyPremium: Bool { moneyPremium }
  private var isMoneyProposed: Bool { moneyPremium && moneyProposed }

  private func updateSearchBarCompact(scrolledPastTop offset: CGFloat) {
    // Com texto na busca, mantém a barra grande.
    if !searchText.isEmpty {
      if searchBarCompact {
        searchBarCompact = false
      }
      return
    }
    let shouldCompact = offset > 24
    guard shouldCompact != searchBarCompact else { return }
    withAnimation(AppMotion.smooth(reduceMotion: reduceMotion)) {
      searchBarCompact = shouldCompact
    }
  }

  private var searchQuery: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var isSearching: Bool { !searchQuery.isEmpty }

  private var visibleAccountGroups: [MoneyAccountGroup] {
    let groups = store.accountGroups()
    guard isSearching else { return groups }
    let q = searchQuery
    var keep = Set(store.accounts.filter { $0.name.localizedStandardContains(q) }.map(\.id))
    keep.formUnion(store.accountsMatchingLedger(query: q))
    for id in Array(keep) {
      if let parent = store.account(id: id)?.parentAccountId {
        keep.insert(parent)
      }
      for card in store.cards(forBankId: id) {
        keep.insert(card.id)
      }
    }
    return groups.compactMap { group in
      if let bank = group.bank {
        let visibleCards = group.cards.filter { keep.contains($0.id) }
        if !keep.contains(bank.id), visibleCards.isEmpty { return nil }
        return MoneyAccountGroup(id: group.id, bank: bank, cards: visibleCards)
      }
      let visibleCards = group.cards.filter { keep.contains($0.id) }
      guard !visibleCards.isEmpty else { return nil }
      return MoneyAccountGroup(id: group.id, bank: nil, cards: visibleCards)
    }
  }

  private var visibleInstallments: [MoneyInstallmentGroup] {
    guard isSearching else { return store.installments }
    return store.installments.filter { $0.matches(searchQuery) }
  }

  private var hasSearchResults: Bool {
    !visibleAccountGroups.isEmpty || !dueRows.isEmpty || !receivableRows.isEmpty || !visibleInstallments.isEmpty
  }

  var body: some View {
    let c = theme.colors

    ScrollViewReader { proxy in
      List {
        if isSearching && !hasSearchResults {
          Section {
            moneyHintRow("Nenhum resultado", position: .only)
          }
        } else {
          if store.showsHubSnapshot, !isSearching {
            snapshotSection
          }
          accountsSection
            .id("money-accounts")
          dueSection
            .id("money-due")
          receivableSection
            .id("money-receivable")
          installmentSection
        }
        Section {
          ListTailSpacer()
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .stackedDashboardListChrome()
      // PreferenceKey dentro de List não sobe no scroll; ScrollGeometry sim.
      .onScrollGeometryChange(for: CGFloat.self) { geo in
        geo.contentOffset.y + geo.contentInsets.top
      } action: { _, offset in
        updateSearchBarCompact(scrolledPastTop: offset)
      }
      .onChange(of: scrollToSection) { _, target in
        guard let target else { return }
        withAnimation(AppMotion.smooth(reduceMotion: reduceMotion)) {
          proxy.scrollTo(target, anchor: .top)
        }
        scrollToSection = nil
      }
    }
    .stackedTabletCentered()
    .stackedThemeBackground(theme)
    .navigationTitle("Dinheiro")
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .top, spacing: 0) {
      // Altura do inset fixa (44 + 8): encolher a barra não remexe contentInsets
      // da List — o fade soft do dashboard volta a funcionar sem o “corte” no scroll.
      let compact = searchBarCompact && searchText.isEmpty
      StackedChromeSearchActionBar(
        text: $searchText,
        prompt: "Conta, parcela ou mês",
        actionAccessibilityLabel: "Adicionar",
        compact: compact,
        action: openAddMenu
      )
      .padding(.horizontal, 18)
      .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .center)
      .padding(.top, -6)
      .padding(.bottom, 8)
    }
    .onChange(of: searchText) { _, text in
      if !text.isEmpty, searchBarCompact {
        withAnimation(AppMotion.smooth(reduceMotion: reduceMotion)) {
          searchBarCompact = false
        }
      }
    }
    .refreshable { await store.load() }
    .navigationDestination(item: $statementRoute) { route in
      MoneyAccountStatementView(accountId: route.accountId)
        .environment(ThemeManager.shared)
    }
    .navigationDestination(item: $cashFlowRoute) { route in
      MoneyCashFlowView(monthId: route.monthId)
        .environment(ThemeManager.shared)
    }
    .task {
      await store.load()
      seedExpandedMonthsIfNeeded()
      try? await _Concurrency.Task.sleep(for: .milliseconds(80))
      snapOpenIds = []
    }
    .taskDetailCover(item: $detailRoute, namespace: taskDetailZoom, onDismiss: {
      _Concurrency.Task { await store.load() }
    }) { route in
      TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(
        subtask: route.subtask,
        parentTaskId: route.parentTaskId,
        parentTaskTitle: route.parentTaskTitle
      ) { snapshot in
        await SubtaskSaveHandler.handle(snapshot) { await store.load() }
      }
      .environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showMovement) {
      MoneyMovementSheet(
        accounts: store.accounts,
        onSave: { accountId, amount, isIncome, title, date, installments in
          store.applyMovement(
            accountId: accountId,
            amount: amount,
            isIncome: isIncome,
            title: title,
            date: date,
            installmentCount: installments
          )
        },
        onTransfer: { fromId, toId, amount, title, date in
          _ = store.transfer(fromAccountId: fromId, toAccountId: toId, amount: amount, title: title, date: date)
        }
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .stackedEditableSheetPresentation(background: c.background)
    }
    .sheet(item: $editingAccount) { account in
      MoneyAccountSheet(account: account) { saved in
        if store.accounts.contains(where: { $0.id == saved.id }) {
          store.updateAccount(saved)
        } else {
          store.addAccount(saved)
        }
      }
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
      .stackedEditableSheetPresentation(background: c.background)
    }
    .alert(
      "Excluir \(accountPendingDelete?.name ?? "conta")?",
      isPresented: Binding(
        get: { accountPendingDelete != nil },
        set: { if !$0 { accountPendingDelete = nil } }
      )
    ) {
      Button("Excluir", role: .destructive) {
        if let id = accountPendingDelete?.id {
          store.deleteAccount(id: id)
        }
        accountPendingDelete = nil
      }
      Button("Cancelar", role: .cancel) { accountPendingDelete = nil }
    } message: {
      if let account = accountPendingDelete, account.kind != .credit, !store.cards(forBankId: account.id).isEmpty {
        Text("Os cartões ligados a esta conta também serão excluídos.")
      } else {
        Text("O extrato desta conta some junto.")
      }
    }
  }

  private func openNewBankAccount() {
    editingAccount = MoneyAccount(
      id: UUID().uuidString,
      name: "",
      kind: .checking,
      balance: 0
    )
  }

  private func openAddMenu(anchor: CGRect) {
    let c = theme.colors
    let banks = store.bankAccounts()
    var items: [PopoverMenuItem] = []

    if !store.accounts.isEmpty {
      items.append(
        PopoverMenuItem(
          id: "movement",
          icon: Hugeicons.moneySend01,
          label: "Novo lançamento",
          iconColor: c.textSecondary
        )
      )
    }
    items.append(
      PopoverMenuItem(
        id: "bank",
        icon: Hugeicons.wallet01,
        label: "Nova conta bancária",
        iconColor: c.textSecondary
      )
    )
    if !banks.isEmpty {
      if banks.count == 1, let bank = banks.first {
        items.append(
          PopoverMenuItem(
            id: "card_\(bank.id)",
            icon: Hugeicons.creditCard,
            label: "Novo cartão",
            iconColor: c.textSecondary
          )
        )
      } else {
        items.append(
          PopoverMenuItem(
            id: "card_menu",
            icon: Hugeicons.creditCard,
            label: "Novo cartão",
            hasArrow: true,
            iconColor: c.textSecondary,
            children: banks.map { bank in
              PopoverMenuItem(
                id: "card_\(bank.id)",
                icon: Hugeicons.creditCard,
                label: bank.name,
                iconColor: c.textSecondary
              )
            }
          )
        )
      }
    }

    presentAnchoredPopover(anchorRect: anchor, items: items, alignTrailing: true) { result in
      guard let result else { return }
      switch result {
      case "movement":
        showMovement = true
      case "bank":
        openNewBankAccount()
      default:
        if result.hasPrefix("card_") {
          let bankId = String(result.dropFirst("card_".count))
          editingAccount = newCardDraft(under: store.account(id: bankId))
        }
      }
    }
  }

  @ViewBuilder
  private var snapshotSection: some View {
    if isMoneyProposed {
      proposedSnapshotSection
    } else if isMoneyPremium {
      premiumSnapshotSection
    } else {
      classicSnapshotSection
    }
  }

  @ViewBuilder
  private var classicSnapshotSection: some View {
    let c = theme.colors
    let due = store.monthTotal
    let invoice = store.openInvoiceTotal
    let total = store.hubSnapshotTotal
    let showsSplit = due > 0 && invoice > 0
    Section {
      VStack(alignment: .leading, spacing: 0) {
        Text("Este mês")
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(c.textTertiary)
        Text(CurrencyFormat.brl(total))
          .font(AppTypography.screenGreeting)
          .monospacedDigit()
          .foregroundStyle(c.accent)
          .padding(.top, 4)
        if showsSplit {
          HStack(alignment: .top, spacing: 12) {
            snapshotSplitColumn(label: "A pagar", amount: due, colors: c, dimmed: false)
            snapshotSplitColumn(label: "Fatura", amount: invoice, colors: c, dimmed: false)
          }
          .padding(.top, 12)
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(c.surfaceVariant)
              HStack(spacing: 0) {
                Rectangle()
                  .fill(c.accent)
                  .frame(width: geo.size.width * CGFloat(due / total))
                Rectangle()
                  .fill(c.accent.opacity(0.35))
                  .frame(width: geo.size.width * CGFloat(invoice / total))
              }
              .clipShape(Capsule())
            }
          }
          .frame(height: 4)
          .padding(.top, 12)
        } else {
          Text(snapshotSingleCaption(due: due, invoice: invoice))
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
            .padding(.top, 4)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Este mês")
      .accessibilityValue(snapshotAccessibilityValue(total: total, due: due, invoice: invoice, showsSplit: showsSplit))
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(style: sectionStyle, position: .only, colors: c)
      )
    }
  }

  @ViewBuilder
  private var premiumSnapshotSection: some View {
    let c = theme.colors
    let liquid = store.liquidBalance
    let due = store.monthTotal + store.openInvoiceTotal
    let incoming = store.monthReceivableItems.reduce(0) { $0 + $1.valor }
    let radius = max(sectionStyle.metrics.cornerRadius, 18)
    Section {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Caixa líquido")
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textSecondary)
          Spacer(minLength: 8)
          Text(liquid < -0.005 ? "Negativo" : "Em dia")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(liquid < -0.005 ? AppColors.dateOverdue : c.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
              Capsule().fill(
                (liquid < -0.005 ? AppColors.dateOverdue : c.textPrimary).opacity(
                  liquid < -0.005 ? 0.14 : 0.06
                )
              )
            )
        }
        Text(CurrencyFormat.brl(liquid))
          .font(AppTypography.screenGreeting)
          .monospacedDigit()
          .foregroundStyle(liquid < -0.005 ? AppColors.dateOverdue : c.accent)
          .padding(.top, 6)
        Text("Corrente + dinheiro · agora")
          .font(.system(size: 12.5))
          .foregroundStyle(c.textTertiary)
          .padding(.top, 3)

        HStack(spacing: 8) {
          premiumHeroChip(
            icon: Hugeicons.banknoteArrowUp,
            label: "A entrar",
            value: "+\(CurrencyFormat.brl(incoming))",
            tint: c.accent,
            colors: c
          )
          premiumHeroChip(
            icon: Hugeicons.banknoteArrowDown,
            label: "A sair",
            value: "−\(CurrencyFormat.brl(due))",
            tint: AppColors.dateOverdue,
            colors: c
          )
        }
        .padding(.top, 14)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(c.surface)
          .overlay(alignment: .top) {
            Capsule()
              .fill(c.accent.opacity(0.55))
              .frame(height: 2)
              .padding(.horizontal, 18)
              .padding(.top, 1)
          }
          .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
              .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 1)
          }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Caixa líquido")
      .accessibilityValue(
        "\(CurrencyFormat.brl(liquid)). A entrar \(CurrencyFormat.brl(incoming)). A sair \(CurrencyFormat.brl(due))"
      )
      .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 6, trailing: 18))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  private var proposedSnapshotSection: some View {
    let c = theme.colors
    let liquid = store.liquidBalance
    let due = store.monthTotal
    let invoice = store.openInvoiceTotal
    let incoming = store.monthReceivableItems.reduce(0) { $0 + $1.valor }
    let radius = max(sectionStyle.metrics.cornerRadius, 18)
    Section {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Caixa líquido")
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textSecondary)
          Spacer(minLength: 8)
          Text(liquid < -0.005 ? "Negativo" : "Em dia")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(liquid < -0.005 ? AppColors.dateOverdue : c.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
              Capsule().fill(
                (liquid < -0.005 ? AppColors.dateOverdue : c.textPrimary).opacity(
                  liquid < -0.005 ? 0.14 : 0.06
                )
              )
            )
        }
        Text(CurrencyFormat.brl(liquid))
          .font(AppTypography.screenGreeting)
          .monospacedDigit()
          .foregroundStyle(liquid < -0.005 ? AppColors.dateOverdue : c.accent)
          .padding(.top, 6)
        Text("Corrente + dinheiro · agora")
          .font(.system(size: 12.5))
          .foregroundStyle(c.textTertiary)
          .padding(.top, 3)

        HStack(spacing: 7) {
          proposedHeroChip(
            label: "A entrar",
            value: "+\(CurrencyFormat.brl(incoming))",
            tint: c.accent,
            colors: c
          ) {
            scrollToSection = "money-receivable"
          }
          proposedHeroChip(
            label: "A pagar",
            value: "−\(CurrencyFormat.brl(due))",
            tint: AppColors.dateOverdue,
            colors: c
          ) {
            scrollToSection = "money-due"
          }
          proposedHeroChip(
            label: "Fatura",
            value: "−\(CurrencyFormat.brl(invoice))",
            tint: AppColors.invoiceAmber,
            colors: c
          ) {
            scrollToSection = "money-accounts"
          }
        }
        .padding(.top, 14)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(c.surface)
          .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
              .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 1)
          }
      }
      .accessibilityElement(children: .contain)
      .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 6, trailing: 18))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  private func proposedHeroChip(
    label: String,
    value: String,
    tint: Color,
    colors c: AppThemeColors,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: {
      HapticService.selection()
      action()
    }) {
      VStack(alignment: .leading, spacing: 3) {
        Text(label)
          .font(.system(size: 10.5, weight: .semibold))
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
        Text(value)
          .font(.system(size: 13, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(tint)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.black.opacity(c.isDark ? 0.22 : 0.04))
      }
    }
    .buttonStyle(.plain)
  }

  private func premiumHeroChip(
    icon: HugeiconsAsset,
    label: String,
    value: String,
    tint: Color,
    colors c: AppThemeColors
  ) -> some View {
    HStack(spacing: 8) {
      StackedIcons.image(icon)
        .font(.system(size: 16))
        .foregroundStyle(tint)
      VStack(alignment: .leading, spacing: 1) {
        Text(label)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(c.textTertiary)
        Text(value)
          .font(.system(size: 14, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(tint)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 11)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.black.opacity(c.isDark ? 0.22 : 0.04))
    }
  }

  private func snapshotSingleCaption(due: Double, invoice: Double) -> String {
    if due > 0 {
      return store.monthCount == 1 ? "1 item a pagar" : "\(store.monthCount) itens a pagar"
    }
    if invoice > 0 {
      return store.nextInvoiceCaption ?? "Fatura \(CurrencyFormat.brl(invoice))"
    }
    return "Nada pendente"
  }

  private func snapshotAccessibilityValue(
    total: Double,
    due: Double,
    invoice: Double,
    showsSplit: Bool
  ) -> String {
    if showsSplit {
      return "\(CurrencyFormat.brl(total)). A pagar \(CurrencyFormat.brl(due)). Fatura \(CurrencyFormat.brl(invoice))"
    }
    return "\(CurrencyFormat.brl(total)). \(snapshotSingleCaption(due: due, invoice: invoice))"
  }

  private func snapshotSplitColumn(
    label: String,
    amount: Double,
    colors c: AppThemeColors,
    dimmed: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(AppTypography.meta)
        .foregroundStyle(c.textTertiary)
      Text(CurrencyFormat.brl(amount))
        .font(AppTypography.cardHeading)
        .monospacedDigit()
        .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var dueSection: some View {
    obligationSection(
      title: "A PAGAR",
      rows: dueRows,
      emptyHint: "Nada com valor pendente",
      showWhenEmpty: true,
      income: false
    )
  }

  @ViewBuilder
  private var receivableSection: some View {
    obligationSection(
      title: "A RECEBER",
      rows: receivableRows,
      emptyHint: "Nada a receber",
      showWhenEmpty: false,
      income: true
    )
  }

  @ViewBuilder
  private func obligationSection(
    title: String,
    rows: [DueRow],
    emptyHint: String,
    showWhenEmpty: Bool,
    income: Bool
  ) -> some View {
    if isSearching, rows.isEmpty {
      EmptyView()
    } else if rows.isEmpty, !showWhenEmpty {
      EmptyView()
    } else {
      Section {
        if rows.isEmpty {
          moneyHintRow(emptyHint, position: .only)
        } else {
          ForEach(rows) { row in
            switch row {
            case .month(let group, let nested, let incomeFlag):
              monthAccordion(group, nested: nested, income: incomeFlag)
            case .year(let year, let months, let id, let incomeFlag):
              yearHeaderCard(year: year, months: months, id: id, income: incomeFlag)
            }
          }
        }
      } header: {
        HomeSectionHeader(text: title, style: sectionStyle, scale: typeScale) {
          if isMoneyProposed, !isSearching {
            let monthTotal = income
              ? store.monthReceivableItems.reduce(0) { $0 + $1.valor }
              : store.monthTotal
            Text(income ? "+\(CurrencyFormat.brl(monthTotal)) · este mês" : "−\(CurrencyFormat.brl(monthTotal)) · este mês")
              .font(typeScale.metrics.actionFont)
              .fontWeight(.semibold)
              .monospacedDigit()
              .foregroundStyle(income ? theme.colors.accent : theme.colors.textPrimary)
              .textCase(nil)
          }
        }
          .homeSectionHeaderInsets(sectionStyle)
      }
    }
  }

  private enum DueRow: Identifiable {
    case month(MoneyMonthGroup, nested: Bool, income: Bool)
    case year(year: Int, months: [MoneyMonthGroup], id: String, income: Bool)

    var id: String {
      switch self {
      case .month(let group, _, _): group.id
      case .year(_, _, let id, _): id
      }
    }
  }

  private var dueRows: [DueRow] {
    outlineRows(from: store.dueOutline, yearPrefix: "year-", income: false)
  }

  private var receivableRows: [DueRow] {
    outlineRows(from: store.receivableOutline, yearPrefix: "recv-year-", income: true)
  }

  private func outlineRows(
    from clusters: [MoneyDueOutline],
    yearPrefix: String,
    income: Bool
  ) -> [DueRow] {
    var rows: [DueRow] = []
    let q = searchQuery
    let currentId = store.currentMonthGroupId
    for cluster in clusters {
      switch cluster {
      case .month(let group):
        if !isSearching || group.matches(q) {
          rows.append(.month(group, nested: false, income: income))
        }
      case .year(let year, let months):
        let yearHit = isSearching && queryMatchesYear(year)
        var visibleMonths = isSearching
          ? (yearHit ? months : months.filter { $0.matches(q) })
          : months
        if isSearching, visibleMonths.isEmpty { continue }
        let yearId = "\(yearPrefix)\(year)"

        if isMoneyProposed, !isSearching,
           let current = visibleMonths.first(where: { $0.calendarMonthId == currentId })
        {
          rows.append(.month(current, nested: false, income: income))
          visibleMonths = visibleMonths.filter { $0.id != current.id }
        }

        if !visibleMonths.isEmpty {
          rows.append(.year(year: year, months: visibleMonths, id: yearId, income: income))
          if expandedMonthIds.contains(yearId) || isSearching {
            for group in visibleMonths {
              rows.append(.month(group, nested: true, income: income))
            }
          }
        }
      }
    }
    return rows
  }

  private func queryMatchesYear(_ year: Int) -> Bool {
    let y = String(year)
    let q = searchQuery
    return y == q || (q.count >= 2 && y.localizedStandardContains(q))
  }

  private func visiblePendingItems(in group: MoneyMonthGroup) -> [MoneyDueItem] {
    guard isSearching else { return group.items }
    if group.nameMatches(searchQuery) { return group.items }
    return group.items.filter { $0.matches(searchQuery) }
  }

  private func visibleCompletedItems(in group: MoneyMonthGroup) -> [MoneyDueItem] {
    guard isSearching else { return group.completedItems }
    if group.nameMatches(searchQuery) { return group.completedItems }
    return group.completedItems.filter { $0.matches(searchQuery) }
  }

  private func yearHeaderCard(
    year: Int,
    months: [MoneyMonthGroup],
    id: String,
    income: Bool
  ) -> some View {
    let expanded = expandedMonthIds.contains(id) || isSearching
    let currentYear = Calendar.current.component(.year, from: Date())
    let quiet = year != currentYear && !expanded
    let monthCount = months.count
    let total = months.reduce(0.0) { $0 + $1.total }
    let subtitle: String = {
      if isMoneyProposed, !isSearching {
        return monthCount == 1 ? "1 mês restante" : "\(monthCount) meses restantes"
      }
      return monthCount == 1 ? "1 mês" : "\(monthCount) meses"
    }()
    return moneyAccordionCard {
      accordionHeader(
        id: id,
        title: "\(year)",
        subtitle: subtitle,
        total: total,
        expanded: expanded,
        emphasizeTitle: !quiet,
        highlightAmount: !quiet,
        quiet: quiet,
        income: income,
        menuItems: [
          PopoverMenuItem(id: "pdf", icon: Hugeicons.pdf01, label: "Gerar PDF"),
        ],
        onMenuResult: { result in
          if result == "pdf" {
            exportDuePDF(year: year, months: months, income: income)
          }
        }
      )
    }
  }

  private func monthAccordion(_ group: MoneyMonthGroup, nested: Bool, income: Bool) -> some View {
    let pending = visiblePendingItems(in: group)
    let completed = visibleCompletedItems(in: group)
    let searchingOpen = isSearching
    let expanded = expandedMonthIds.contains(group.id) || searchingOpen
    let mounted = mountedMonthIds.contains(group.id) || searchingOpen
    let completedExpanded = expandedMonthIds.contains(group.completedSectionId)
    let isCurrent = group.calendarMonthId == store.currentMonthGroupId
    let c = theme.colors
    let count = isSearching ? pending.count : group.count
    let total = isSearching ? pending.reduce(0) { $0 + $1.valor } : group.total
    var subtitle: String
    if isSearching, pending.isEmpty, !completed.isEmpty {
      subtitle = completed.count == 1 ? "1 concluído" : "\(completed.count) concluídos"
    } else {
      subtitle = count == 1 ? "1 item" : "\(count) itens"
      if isCurrent { subtitle += " · este mês" }
    }
    return moneyAccordionCard(nested: nested, emphasizeCurrent: isMoneyProposed && isCurrent) {
      VStack(spacing: 0) {
        accordionHeader(
          id: group.id,
          title: group.title,
          subtitle: isMoneyProposed && isCurrent
            ? (count == 1 ? "este mês · 1 pendente" : "este mês · \(count) pendentes")
            : subtitle,
          total: total,
          expanded: expanded,
          income: income,
          menuItems: [
            PopoverMenuItem(id: "cashflow", icon: Hugeicons.chart01, label: "Fluxo de caixa"),
            PopoverMenuItem(id: "pdf", icon: Hugeicons.pdf01, label: "Gerar PDF"),
          ],
          onMenuResult: { result in
            if result == "pdf" {
              exportDuePDF(group, income: income)
            } else if result == "cashflow" {
              openCashFlow(group)
            }
          }
        )
        if mounted {
          SubtaskExpandReveal(
            expanded: expanded,
            reduceMotion: reduceMotion,
            contentRevision: panelRevision(for: group),
            stabilizeSelfSizingParent: true,
            snapOpen: snapOpenIds.contains(group.id),
            sizeRevision: completedSizeRevision(for: group),
            panelFill: c.surface
          ) {
            VStack(spacing: 0) {
              ForEach(pending) { item in
                accordionDivider
                dueItemRow(item, income: income)
              }
              if !completed.isEmpty {
                accordionDivider
                accordionHeader(
                  id: group.completedSectionId,
                  title: "Concluído",
                  subtitle: completed.count == 1 ? "1 item" : "\(completed.count) itens",
                  total: completed.reduce(0) { $0 + $1.valor },
                  expanded: completedExpanded,
                  highlightAmount: !isMoneyProposed,
                  quiet: isMoneyProposed,
                  income: income
                )
                if completedExpanded {
                  ForEach(completed) { item in
                    accordionDivider
                    dueItemRow(item, completed: true, income: income)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  private func accordionHeader(
    id: String,
    title: String,
    subtitle: String,
    total: Double,
    expanded: Bool,
    emphasizeTitle: Bool = false,
    highlightAmount: Bool = true,
    quiet: Bool = false,
    income: Bool = false,
    menuItems: [PopoverMenuItem] = [],
    onMenuResult: ((String) -> Void)? = nil
  ) -> some View {
    let label = accordionHeaderLabel(
      id: id,
      title: title,
      subtitle: subtitle,
      total: total,
      expanded: expanded,
      emphasizeTitle: emphasizeTitle,
      highlightAmount: highlightAmount,
      quiet: quiet,
      income: income
    )
    return Group {
      if menuItems.isEmpty {
        Button {
          HapticService.selection()
          toggleExpanded(id)
        } label: {
          label
        }
        .buttonStyle(.plain)
      } else {
        SubtaskTitlePressArea(
          onTap: {
            HapticService.selection()
            toggleExpanded(id)
          },
          extraItems: menuItems,
          showsDelete: false,
          onMenuResult: onMenuResult
        ) {
          label
        }
      }
    }
    .accessibilityLabel(expanded ? "Recolher \(title)" : "Expandir \(title)")
    .accessibilityValue("\(subtitle), \(CurrencyFormat.brl(total))")
    .accessibilityHint(menuItems.isEmpty ? "" : "Toque para abrir. Toque e segure para fluxo de caixa ou PDF.")
  }

  private func accordionHeaderLabel(
    id: String,
    title: String,
    subtitle: String,
    total: Double,
    expanded: Bool,
    emphasizeTitle: Bool,
    highlightAmount: Bool,
    quiet: Bool,
    income: Bool
  ) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      SubtaskExpandChevron(expanded: expanded, size: 12, taskId: id)
        .frame(width: HomeSectionRowLayout.iconWidth)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(t.rowTitleFont)
          .fontWeight(emphasizeTitle ? .bold : .semibold)
          .foregroundStyle(quiet ? c.textTertiary : c.textPrimary)
          .lineLimit(1)
        Text(subtitle)
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
      }
      .layoutPriority(1)
      Spacer(minLength: 8)
      Text(income ? "+\(CurrencyFormat.brl(total))" : (isMoneyPremium && !income ? "−\(CurrencyFormat.brl(total))" : CurrencyFormat.brl(total)))
        .font(t.rowCountFont)
        .monospacedDigit()
        .fontWeight(.semibold)
        .foregroundStyle(
          highlightAmount
            ? (isMoneyPremium
              ? (income ? c.accent : c.textPrimary)
              : c.accent)
            : c.textTertiary
        )
        .lineLimit(1)
        .fixedSize()
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())
  }

  private func exportDuePDF(_ group: MoneyMonthGroup, income: Bool = false) {
    HapticService.selection()
    if let url = MoneyDuePDF.fileURL(for: group, income: income) {
      MoneySharePresenter.present(url)
    }
  }

  private func openCashFlow(_ group: MoneyMonthGroup) {
    HapticService.selection()
    guard MoneyCalendar.monthStart(fromMonthId: group.calendarMonthId) != nil else { return }
    cashFlowRoute = MoneyCashFlowRoute(monthId: group.calendarMonthId)
  }

  private func exportDuePDF(year: Int, months: [MoneyMonthGroup], income: Bool = false) {
    HapticService.selection()
    if let url = MoneyDuePDF.fileURL(year: year, months: months, income: income) {
      MoneySharePresenter.present(url)
    }
  }

  private func dueItemRow(_ item: MoneyDueItem, completed: Bool = false, income: Bool = false) -> some View {
    let overdue = !completed && item.isOverdue
    let c = theme.colors
    return Button {
      HapticService.selection()
      subtaskDetailRoute = SubtaskDetailRoute(
        subtask: item.subtask,
        parentTaskId: item.parent.id,
        parentTaskTitle: item.parent.title
      )
    } label: {
      moneyValueRow(
        title: item.title,
        subtitle: item.subtitle,
        amount: item.valor,
        highlight: !completed,
        dimmed: completed,
        overdue: overdue,
        income: income,
        leadingIcon: isMoneyPremium
          ? (income ? Hugeicons.banknoteArrowUp : Hugeicons.banknoteArrowDown)
          : nil,
        amountColor: isMoneyPremium && !completed
          ? (income ? c.accent : (overdue ? AppColors.dateOverdue : c.textPrimary))
          : nil,
        iconColor: isMoneyPremium ? c.textSecondary : nil
      )
      .padding(.horizontal, 12)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .accessibilityValue(
      overdue
        ? "\(item.dueLabel), atrasado, \(income ? "+" : "")\(CurrencyFormat.brl(item.valor))"
        : "\(item.subtitle), \(income ? "+" : "")\(CurrencyFormat.brl(item.valor))"
    )
  }

  private var accordionDivider: some View {
    let c = theme.colors
    return Rectangle()
      .fill(c.textPrimary.opacity(TaskExpandDividerStyle.cardLightStrokeAlpha))
      .frame(height: TaskExpandDividerStyle.listHairlineThickness)
      .padding(.leading, 12 + HomeSectionRowLayout.iconWidth + HomeSectionRowLayout.iconSpacing)
  }

  private func moneyAccordionCard<Content: View>(
    nested: Bool = false,
    emphasizeCurrent: Bool = false,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let c = theme.colors
    let radius = max(sectionStyle.metrics.cornerRadius, 14)
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    let leading: CGFloat = nested ? 18 + HomeSectionRowLayout.iconWidth : 18
    // Stroke no overlay (por cima): o painel expandido é full-bleed e cobria a
    // borda quando ela vivia no background — só o header “este mês” ficava contornado.
    return content()
      .background {
        shape.fill(c.surface)
      }
      .clipShape(shape)
      .overlay {
        if emphasizeCurrent {
          shape.strokeBorder(c.accent.opacity(0.28), lineWidth: 1)
        }
      }
      .listRowInsets(EdgeInsets(top: 3, leading: leading, bottom: 3, trailing: 18))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
  }

  private func toggleExpanded(_ id: String) {
    let willExpand = !expandedMonthIds.contains(id)
    let apply = {
      if willExpand {
        mountedMonthIds.insert(id)
        expandedMonthIds.insert(id)
      } else {
        if id.hasPrefix("year-") {
          collapseMonths(insideYearId: id)
        }
        expandedMonthIds.remove(id)
        scheduleAccordionUnmount(id)
      }
    }
    if id.hasPrefix("year-") {
      withAnimation(.easeOut(duration: reduceMotion ? 0 : 0.22)) { apply() }
    } else {
      apply()
    }
    persistExpandedMonths()
  }

  private func collapseMonths(insideYearId id: String) {
    guard case .year(_, let months) = store.dueOutline.first(where: { $0.id == id }) else { return }
    for group in months {
      expandedMonthIds.remove(group.id)
      expandedMonthIds.remove(group.completedSectionId)
      mountedMonthIds.remove(group.id)
      mountedMonthIds.remove(group.completedSectionId)
    }
  }

  private func scheduleAccordionUnmount(_ id: String) {
    _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(reduceMotion ? 0 : 380))
      guard !expandedMonthIds.contains(id) else { return }
      mountedMonthIds.remove(id)
    }
  }

  private func panelRevision(for group: MoneyMonthGroup) -> Int {
    var hasher = Hasher()
    hasher.combine(group.id)
    hasher.combine(searchQuery)
    for item in visiblePendingItems(in: group) {
      hasher.combine(item.id)
      hasher.combine(item.valor)
    }
    for item in visibleCompletedItems(in: group) {
      hasher.combine(item.id)
      hasher.combine(item.valor)
    }
    return hasher.finalize()
  }

  private func completedSizeRevision(for group: MoneyMonthGroup) -> Int {
    var hasher = Hasher()
    hasher.combine(group.id)
    hasher.combine(expandedMonthIds.contains(group.completedSectionId))
    hasher.combine(group.completedCount)
    return hasher.finalize()
  }

  private func seedExpandedMonthsIfNeeded() {
    guard !didSeedExpandedMonths else { return }
    didSeedExpandedMonths = true
    if let saved = MoneyDueExpandedStorage.load() {
      expandedMonthIds = saved
      mountedMonthIds = saved
      snapOpenIds = saved
      return
    }
    let currentMonth = store.currentMonthGroupId
    let currentYear = Calendar.current.component(.year, from: Date())
    let yearId = "year-\(currentYear)"
    var initial: Set<String> = []
    // Proposto: só o mês atual aberto — o ano fica colapsado.
    if !isMoneyProposed, store.dueOutline.contains(where: { $0.id == yearId }) {
      initial.insert(yearId)
    }
    if !isMoneyProposed, store.receivableOutline.contains(where: {
      if case .year(let year, _) = $0 { return year == currentYear }
      return false
    }) {
      initial.insert("recv-year-\(currentYear)")
    }
    if store.monthGroups.contains(where: { $0.id == currentMonth }) {
      initial.insert(currentMonth)
    }
    if store.receivableMonthGroups.contains(where: { $0.calendarMonthId == currentMonth }) {
      initial.insert("recv-\(currentMonth)")
    }
    expandedMonthIds = initial
    mountedMonthIds = initial
    snapOpenIds = initial
    persistExpandedMonths()
  }

  private func persistExpandedMonths() {
    MoneyDueExpandedStorage.save(expandedMonthIds)
  }

  @ViewBuilder
  private var installmentSection: some View {
    let c = theme.colors
    let items = visibleInstallments
    if !items.isEmpty {
      Section {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, group in
          Button {
            HapticService.selection()
            detailRoute = TaskDetailRoute(taskId: group.id)
          } label: {
            HStack(spacing: HomeSectionRowLayout.iconSpacing) {
              VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                  .font(typeScale.metrics.rowTitleFont)
                  .foregroundStyle(c.textPrimary)
                  .lineLimit(1)
                Text(group.snapshot.label)
                  .font(AppTypography.screenSubtitle)
                  .foregroundStyle(c.textTertiary)
                  .lineLimit(1)
              }
              Spacer(minLength: 8)
              SubtaskProgressRing(
                done: group.snapshot.done,
                total: max(group.snapshot.total, 1),
                size: 28
              )
            }
            .padding(.vertical, sectionStyle.metrics.rowPaddingV)
          }
          .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
          .listRowInsets(sectionStyle.metrics.rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(
            HomeSectionRowBackground(
              style: sectionStyle,
              position: .at(index: index, count: items.count),
              colors: c
            )
          )
        }
      } header: {
        HomeSectionHeader(text: "PARCELAS", style: sectionStyle, scale: typeScale)
          .homeSectionHeaderInsets(sectionStyle)
      }
    }
  }

  @ViewBuilder
  private var accountsSection: some View {
    let c = theme.colors
    let groups = visibleAccountGroups
    if isSearching, groups.isEmpty {
      EmptyView()
    } else {
    Section {
      if groups.isEmpty {
        moneyHintRow("O saldo de cada banco aparece aqui. Cartões ficam dentro do banco.", position: .first)
      } else {
        ForEach(groups) { group in
          accountGroupCard(group)
        }
      }
    } header: {
      HomeSectionHeader(
        text: "CONTAS",
        style: sectionStyle,
        scale: typeScale,
        isFirstSection: !store.showsHubSnapshot || isSearching
      ) {
        if !isSearching, groups.contains(where: { $0.bank != nil }) {
          if isMoneyProposed {
            let banks = groups.filter { $0.bank != nil }.count
            let cards = groups.reduce(0) { $0 + $1.cards.count }
            Text("\(banks) bancos · \(cards) cartões")
              .foregroundStyle(c.textSecondary)
              .font(typeScale.metrics.actionFont)
              .textCase(nil)
          } else {
            HStack(spacing: 4) {
              Text(CurrencyFormat.brl(store.liquidBalance))
                .foregroundStyle(c.accent)
                .fontWeight(.semibold)
              Text("líquido")
                .foregroundStyle(c.textSecondary)
            }
            .font(typeScale.metrics.actionFont)
            .monospacedDigit()
            .textCase(nil)
            .accessibilityLabel("\(CurrencyFormat.brl(store.liquidBalance)) líquido")
          }
        }
      }
        .homeSectionHeaderInsets(sectionStyle)
    }
    }
  }

  private func accountGroupCard(_ group: MoneyAccountGroup) -> some View {
    let c = theme.colors
    let radius = max(sectionStyle.metrics.cornerRadius, 14)
    let innerFill = c.isDark ? Color.black.opacity(0.18) : Color.black.opacity(0.04)
    return VStack(spacing: 0) {
      if let bank = group.bank {
        accountPressRow(bank, nested: false, orphan: false)
          .padding(.horizontal, 12)
        if !group.cards.isEmpty {
          accountGroupHairline()
          VStack(spacing: 0) {
            ForEach(Array(group.cards.enumerated()), id: \.element.id) { index, card in
              if index > 0 {
                accountGroupHairline()
              }
              accountPressRow(card, nested: true, orphan: false)
                .padding(.horizontal, 12)
            }
          }
          .background(innerFill)
        }
      } else {
        ForEach(group.cards) { card in
          accountPressRow(card, nested: true, orphan: true)
            .padding(.horizontal, 12)
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(c.surface)
    }
    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    .listRowInsets(EdgeInsets(top: 3, leading: 18, bottom: 3, trailing: 18))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func accountGroupHairline() -> some View {
    let c = theme.colors
    return Rectangle()
      .fill(c.textPrimary.opacity(TaskExpandDividerStyle.cardLightStrokeAlpha))
      .frame(height: TaskExpandDividerStyle.listHairlineThickness)
  }

  @ViewBuilder
  private func accountPressRow(_ account: MoneyAccount, nested: Bool, orphan: Bool) -> some View {
    let banks = store.bankAccounts()
    let extraItems: [PopoverMenuItem] = {
      if account.kind != .credit {
        return [
          PopoverMenuItem(
            id: "new-card",
            icon: Hugeicons.creditCard,
            label: "Novo cartão"
          )
        ]
      }
      guard orphan, !banks.isEmpty else { return [] }
      if banks.count == 1, let bank = banks.first {
        return [
          PopoverMenuItem(
            id: "link_\(bank.id)",
            icon: Hugeicons.wallet01,
            label: "Vincular a \(bank.name)"
          )
        ]
      }
      return [
        PopoverMenuItem(
          id: "link_menu",
          icon: Hugeicons.wallet01,
          label: "Vincular a conta",
          hasArrow: true,
          children: banks.map { bank in
            PopoverMenuItem(
              id: "link_\(bank.id)",
              icon: Hugeicons.wallet01,
              label: bank.name
            )
          }
        )
      ]
    }()
    SubtaskTitlePressArea(
      onTap: {
        HapticService.selection()
        statementRoute = MoneyStatementRoute(accountId: account.id)
      },
      onDelete: {
        accountPendingDelete = account
      },
      deleteLabel: account.kind == .credit ? "Excluir cartão" : "Excluir conta",
      extraItems: extraItems,
      onMenuResult: { result in
        if result == "new-card" {
          editingAccount = newCardDraft(under: account)
          return
        }
        if result.hasPrefix("link_") {
          let bankId = String(result.dropFirst("link_".count))
          linkCard(account, toBankId: bankId)
        }
      }
    ) {
      accountValueRow(account, nested: nested, orphan: orphan)
    }
  }

  private func linkCard(_ card: MoneyAccount, toBankId: String) {
    guard store.account(id: toBankId) != nil else { return }
    HapticService.selection()
    var updated = card
    updated.parentAccountId = toBankId
    store.updateAccount(updated)
  }

  private func newCardDraft(under bank: MoneyAccount?) -> MoneyAccount {
    MoneyAccount(
      id: UUID().uuidString,
      name: "",
      kind: .credit,
      balance: 0,
      dueDay: nil,
      closingDay: nil,
      invoiceAmount: 0,
      parentAccountId: bank?.id ?? store.bankAccounts().first?.id
    )
  }

  private func accountLimitUsage(for account: MoneyAccount) -> Double? {
    guard let usage = store.limitUsage(for: account) ?? account.limitUsage, usage > 0 else {
      return nil
    }
    return usage
  }

  @ViewBuilder
  private func accountValueRow(_ account: MoneyAccount, nested: Bool, orphan: Bool) -> some View {
    let c = theme.colors
    let isCredit = account.kind == .credit
    let premiumIcon: HugeiconsAsset? = {
      guard isMoneyPremium else {
        return nested || orphan ? Hugeicons.creditCard : nil
      }
      switch account.kind {
      case .credit: return Hugeicons.creditCard
      case .cash: return Hugeicons.money01
      case .checking: return Hugeicons.wallet01
      }
    }()
    let amountTint: Color? = {
      guard isMoneyPremium else { return nil }
      if isCredit {
        return (account.invoiceAmount ?? 0) > 0 ? c.textPrimary : c.textTertiary
      }
      if isMoneyProposed { return c.accent }
      return nil
    }()
    let iconTint: Color? = {
      guard isMoneyPremium else { return nil }
      return c.textSecondary
    }()
    let barTint: Color? = {
      guard isMoneyPremium, let usage = accountLimitUsage(for: account) else { return nil }
      if usage >= 0.8 { return AppColors.dateOverdue }
      if usage >= 0.55 { return AppColors.invoiceAmber }
      return c.textQuaternary
    }()
    moneyValueRow(
      title: account.name,
      subtitle: cardSubtitle(account, orphan: orphan),
      amount: account.displayAmount,
      highlight: account.highlightsAmount,
      dimmed: isCredit && (account.invoiceAmount ?? 0) == 0,
      usage: accountLimitUsage(for: account),
      leadingIcon: premiumIcon,
      nestedIndent: nested && !orphan,
      subtitleEmphasis: isMoneyProposed ? nil : limitCaption(for: account),
      amountColor: amountTint,
      iconColor: iconTint,
      usageColor: barTint,
      limitPercentLabel: isMoneyProposed ? limitPercentChip(for: account) : nil,
      thickerLimitBar: isMoneyProposed
    )
  }

  private func cardSubtitle(_ account: MoneyAccount, orphan: Bool) -> String {
    var parts: [String] = []
    if orphan {
      parts.append("Sem banco vinculado")
      if account.kind == .credit {
        let dates = account.kindCaption
        if !dates.isEmpty, dates != "Fatura aberta" {
          parts.append(dates)
        }
      }
    } else {
      parts.append(account.kindCaption)
    }
    let remaining = store.futureInstallmentCount(for: account.id)
    if remaining > 0 {
      parts.append("\(remaining)×")
    }
    return parts.joined(separator: " · ")
  }

  private func limitCaption(for account: MoneyAccount) -> String? {
    guard let usage = accountLimitUsage(for: account) else { return nil }
    let percent = Int((usage * 100).rounded())
    return "\(percent)% do limite"
  }

  private func limitPercentChip(for account: MoneyAccount) -> String? {
    guard let usage = accountLimitUsage(for: account) else { return nil }
    return "\(Int((usage * 100).rounded()))%"
  }

  private func moneyValueRow(
    title: String,
    subtitle: String,
    amount: Double,
    highlight: Bool,
    dimmed: Bool = false,
    usage: Double? = nil,
    overdue: Bool = false,
    income: Bool = false,
    leadingIcon: HugeiconsAsset? = nil,
    nestedIndent: Bool = false,
    subtitleEmphasis: String? = nil,
    amountColor: Color? = nil,
    iconColor: Color? = nil,
    usageColor: Color? = nil,
    limitPercentLabel: String? = nil,
    thickerLimitBar: Bool = false
  ) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let contentLeadingInset = leadingIcon != nil
      ? HomeSectionRowLayout.iconWidth + HomeSectionRowLayout.iconSpacing
      : 0
    let resolvedAmount: Color = {
      if let amountColor { return amountColor }
      if highlight { return c.accent }
      return c.textSecondary
    }()
    return VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: HomeSectionRowLayout.iconSpacing) {
        if let leadingIcon {
          StackedIcons.image(leadingIcon)
            .font(.system(size: 20))
            .foregroundStyle(iconColor ?? c.textSecondary)
            .frame(width: HomeSectionRowLayout.iconWidth, alignment: .center)
            .padding(.top, 1)
        }
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 8) {
            Text(title)
              .font(t.rowTitleFont)
              .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
              .lineLimit(1)
              .layoutPriority(1)
            Spacer(minLength: 8)
            Text(income ? "+\(CurrencyFormat.brl(amount))" : CurrencyFormat.brl(amount))
              .font(t.rowCountFont)
              .monospacedDigit()
              .fontWeight(highlight || amountColor != nil ? .semibold : .regular)
              .foregroundStyle(dimmed ? c.textTertiary : resolvedAmount)
              .lineLimit(1)
              .fixedSize()
          }
          if overdue {
            overdueSubtitle(subtitle, colors: c)
          } else if !subtitle.isEmpty || subtitleEmphasis != nil {
            accountSubtitleText(base: subtitle, emphasis: subtitleEmphasis, colors: c)
          }
        }
        .layoutPriority(1)
      }
      if let usage {
        let fill = usageColor ?? c.accent
        HStack(spacing: 8) {
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(c.surfaceVariant)
              Capsule()
                .fill(
                  LinearGradient(
                    colors: [
                      fill.opacity(0.18),
                      fill.opacity(0.55),
                      fill.opacity(0.92),
                      fill,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .frame(width: max(4, geo.size.width * usage))
            }
          }
          .frame(height: thickerLimitBar ? 5 : 3)
          if let limitPercentLabel {
            Text(limitPercentLabel)
              .font(.system(size: 10.5, weight: .bold))
              .foregroundStyle(c.textTertiary)
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background {
                Capsule().fill(c.textPrimary.opacity(0.05))
              }
          }
        }
        .padding(.leading, contentLeadingInset)
      }
    }
    .padding(.leading, nestedIndent ? 10 : 0)
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
  }

  private func accountSubtitleText(base: String, emphasis: String?, colors c: AppThemeColors) -> some View {
    var text = AttributedString(base)
    text.foregroundColor = c.textTertiary
    if let emphasis, !emphasis.isEmpty {
      if !base.isEmpty {
        var sep = AttributedString(" · ")
        sep.foregroundColor = c.textTertiary
        text.append(sep)
      }
      var extra = AttributedString(emphasis)
      extra.foregroundColor = c.textSecondary
      text.append(extra)
    }
    return Text(text)
      .font(AppTypography.screenSubtitle)
      .lineLimit(1)
  }

  private func overdueSubtitle(_ subtitle: String, colors c: AppThemeColors) -> some View {
    let parts = subtitle.split(separator: "·", maxSplits: 1, omittingEmptySubsequences: false)
    let date = parts.first.map { $0.trimmingCharacters(in: .whitespaces) } ?? subtitle
    let rest = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
    var text = AttributedString(date)
    text.foregroundColor = AppColors.dateOverdue
    var overdueMark = AttributedString(" · atrasado")
    overdueMark.foregroundColor = AppColors.dateOverdue
    text.append(overdueMark)
    if !rest.isEmpty {
      var extra = AttributedString(" · \(rest)")
      extra.foregroundColor = c.textTertiary
      text.append(extra)
    }
    return Text(text)
      .font(AppTypography.screenSubtitle)
      .lineLimit(1)
  }

  private func moneyHintRow(_ text: String, position: HomeSectionRowPosition) -> some View {
    let c = theme.colors
    return Text(text)
      .font(typeScale.metrics.rowTitleFont)
      .foregroundStyle(c.textTertiary)
      .padding(.vertical, sectionStyle.metrics.rowPaddingV)
      .listRowInsets(sectionStyle.metrics.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(style: sectionStyle, position: position, colors: c)
      )
  }
}

private enum MoneyDueExpandedStorage {
  private static var key: String {
    let uid = SupabaseService.client.auth.currentUser?.id.uuidString ?? "anon"
    return "money.dueExpanded.v1.\(uid)"
  }

  static func load() -> Set<String>? {
    guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
    let raw = UserDefaults.standard.array(forKey: key) as? [String] ?? []
    return Set(raw)
  }

  static func save(_ ids: Set<String>) {
    UserDefaults.standard.set(Array(ids), forKey: key)
  }
}

struct MoneyAccountSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let onSave: (MoneyAccount) -> Void

  @State private var name: String
  @State private var kind: MoneyAccount.Kind
  @State private var balanceText: String
  @State private var dueDayText: String
  @State private var closingDayText: String
  @State private var invoiceText: String
  @State private var parentAccountId: String?
  private let accountId: String
  @State private var moneyStore = MoneyStore.shared

  init(account: MoneyAccount, onSave: @escaping (MoneyAccount) -> Void) {
    self.onSave = onSave
    accountId = account.id
    _name = State(initialValue: account.name)
    _kind = State(initialValue: account.kind)
    _balanceText = State(
      initialValue: account.balance == 0 ? "" : String(format: "%.2f", account.balance)
    )
    _dueDayText = State(initialValue: account.dueDay.map(String.init) ?? "")
    _closingDayText = State(initialValue: account.closingDay.map(String.init) ?? "")
    _invoiceText = State(
      initialValue: (account.invoiceAmount ?? 0) == 0
        ? ""
        : String(format: "%.2f", account.invoiceAmount ?? 0)
    )
    _parentAccountId = State(initialValue: account.parentAccountId)
  }

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var canSave: Bool { !trimmedName.isEmpty }

  var body: some View {
    let c = theme.colors
    NavigationStack {
      List {
        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              MoneySheetFieldRow(
                label: "Nome",
                text: $name,
                placeholder: kind == .credit ? "Ex: Itaú Cartão" : "Ex: Nubank"
              )
              SettingsCardDivider(leadingPadding: 14)
              MoneySheetSelectRow(label: "Tipo", value: kind.label) { rect in
                showKindMenu(anchor: rect)
              }
              SettingsCardDivider(leadingPadding: 14)
              MoneySheetFieldRow(
                label: kind == .credit ? "Limite" : "Saldo",
                text: $balanceText,
                placeholder: "0,00",
                keyboard: .decimalPad
              )
              if kind == .credit {
                SettingsCardDivider(leadingPadding: 14)
                MoneySheetSelectRow(
                  label: "Banco",
                  value: parentBankName
                ) { rect in
                  showBankMenu(anchor: rect)
                }
                SettingsCardDivider(leadingPadding: 14)
                MoneySheetFieldRow(
                  label: "Fecha",
                  text: $closingDayText,
                  placeholder: "Dia",
                  keyboard: .numberPad
                )
                SettingsCardDivider(leadingPadding: 14)
                MoneySheetFieldRow(
                  label: "Vencimento",
                  text: $dueDayText,
                  placeholder: "Dia",
                  keyboard: .numberPad
                )
                SettingsCardDivider(leadingPadding: 14)
                MoneySheetFieldRow(
                  label: "Fatura",
                  text: $invoiceText,
                  placeholder: "0,00",
                  keyboard: .decimalPad
                )
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .settingsListCardRow(top: 8, bottom: 8)
        }
      }
      .settingsDrillDownList(background: c.background)
      .listSectionSpacing(16)
      .popoverHostScope()
      .navigationTitle(
        trimmedName.isEmpty
          ? (kind == .credit ? "Novo cartão" : "Nova conta")
          : "Editar conta"
      )
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        let isolate = GlassChromePreference.prefersStaticToolbarPills()
        ToolbarItem(id: "stacked-money-account-cancel", placement: .cancellationAction) {
          StackedToolbarTextButton(title: "Cancelar") { dismiss() }
        }
        .stackedToolbarGlassIsolation(isolate)
        ToolbarItem(id: "stacked-money-account-save", placement: .confirmationAction) {
          StackedToolbarTextButton(title: "Guardar", accent: true, enabled: canSave) {
            guard canSave else { return }
            onSave(
              MoneyAccount(
                id: accountId,
                name: trimmedName,
                kind: kind,
                balance: InstallmentGeneratorLogic.parseValor(balanceText) ?? 0,
                dueDay: Int(dueDayText),
                closingDay: Int(closingDayText),
                invoiceAmount: kind == .credit
                  ? InstallmentGeneratorLogic.parseValor(invoiceText)
                  : nil,
                parentAccountId: kind == .credit ? parentAccountId : nil
              )
            )
            dismiss()
          }
        }
        .stackedToolbarGlassIsolation(isolate)
      }
    }
  }

  private func showKindMenu(anchor: CGRect) {
    let items = MoneyAccount.Kind.allCases.map { item in
      PopoverMenuItem(
        id: item.rawValue,
        icon: Self.icon(for: item),
        label: item.label,
        selected: kind == item
      )
    }
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result, let selected = MoneyAccount.Kind(rawValue: result) else { return }
      kind = selected
    }
  }

  private var parentBankName: String {
    if let parentAccountId, let bank = moneyStore.account(id: parentAccountId) {
      return bank.name
    }
    return "Nenhuma conta"
  }

  private func showBankMenu(anchor: CGRect) {
    let banks = moneyStore.bankAccounts(excluding: accountId)
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(
        id: "none",
        icon: Hugeicons.cancel01,
        label: "Nenhuma conta",
        selected: parentAccountId == nil
      )
    ]
    items.append(contentsOf: banks.map { bank in
      PopoverMenuItem(
        id: bank.id,
        icon: Hugeicons.wallet01,
        label: bank.name,
        selected: parentAccountId == bank.id
      )
    })
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      parentAccountId = result == "none" ? nil : result
    }
  }

  private static func icon(for kind: MoneyAccount.Kind) -> HugeiconsAsset {
    switch kind {
    case .checking: Hugeicons.wallet01
    case .credit: Hugeicons.creditCard
    case .cash: Hugeicons.money01
    }
  }
}

struct MoneyMovementSheet: View {
  enum Kind {
    case income
    case expense
    case transfer

    var typeLabel: String {
      switch self {
      case .income: "Entrada"
      case .expense: "Saída"
      case .transfer: "Transferência"
      }
    }
  }

  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let accounts: [MoneyAccount]
  let editingEntry: MoneyLedgerEntry?
  let onSave: (String, Double, Bool, String?, Date, Int) -> Void
  let onTransfer: (String, String, Double, String?, Date) -> Void
  let onUpdate: ((String, String, Double, Bool, String?, Date, Int) -> Void)?

  @State private var kind: Kind
  @State private var amountText = ""
  @State private var note = ""
  @State private var occurredOn: Date
  @State private var showDatePicker = false
  @State private var accountId: String
  @State private var fromAccountId: String
  @State private var toAccountId: String
  @State private var installmentCount = 1

  init(
    accounts: [MoneyAccount],
    initialAccountId: String? = nil,
    startsAsTransfer: Bool = false,
    editing: MoneyLedgerEntry? = nil,
    onSave: @escaping (String, Double, Bool, String?, Date, Int) -> Void,
    onTransfer: @escaping (String, String, Double, String?, Date) -> Void,
    onUpdate: ((String, String, Double, Bool, String?, Date, Int) -> Void)? = nil
  ) {
    self.accounts = accounts
    self.editingEntry = editing
    self.onSave = onSave
    self.onTransfer = onTransfer
    self.onUpdate = onUpdate
    let transferable = accounts.filter { $0.kind != .credit }
    let preferred = (editing?.accountId ?? initialAccountId).flatMap { id in
      accounts.contains(where: { $0.id == id }) ? id : nil
    }
    let preferredBank = preferred.flatMap { id in
      accounts.first(where: { $0.id == id && $0.kind != .credit })?.id
    }
    let from = preferredBank ?? transferable.first?.id ?? accounts.first?.id ?? ""
    let to = transferable.first(where: { $0.id != from })?.id ?? ""
    _accountId = State(initialValue: preferred ?? from)
    _fromAccountId = State(initialValue: from)
    _toAccountId = State(initialValue: to)
    _occurredOn = State(initialValue: Calendar.current.startOfDay(for: editing?.date ?? Date()))
    if let editing {
      let plan = MoneyStore.shared.installmentPlan(for: editing.id)
      _kind = State(initialValue: editing.isIncome ? .income : .expense)
      let fallbacks: Set<String> = ["Entrada", "Saída"]
      _note = State(initialValue: fallbacks.contains(editing.title) ? "" : editing.title)
      if plan.count > 1 {
        let total = plan.reduce(0) { $0 + $1.amount }
        _amountText = State(initialValue: InstallmentGeneratorLogic.editingText(for: total))
        _installmentCount = State(initialValue: plan.first?.installmentCount ?? plan.count)
        _occurredOn = State(initialValue: Calendar.current.startOfDay(for: plan.first?.date ?? editing.date))
      } else {
        _amountText = State(initialValue: InstallmentGeneratorLogic.editingText(for: editing.amount))
      }
    } else {
      _kind = State(initialValue: startsAsTransfer && transferable.count >= 2 ? .transfer : .expense)
    }
  }

  private var isEditing: Bool { editingEntry != nil }

  private var parsedAmount: Double? {
    InstallmentGeneratorLogic.parseValor(amountText)
  }

  private var selectedAccount: MoneyAccount? {
    accounts.first { $0.id == accountId }
  }

  private var transferableAccounts: [MoneyAccount] {
    accounts.filter { $0.kind != .credit }
  }

  private var canTransferBetweenAccounts: Bool {
    transferableAccounts.count >= 2
  }

  private var fromAccount: MoneyAccount? {
    accounts.first { $0.id == fromAccountId }
  }

  private var toAccount: MoneyAccount? {
    accounts.first { $0.id == toAccountId }
  }

  private var showsInstallments: Bool {
    kind == .expense && selectedAccount?.kind == .credit
  }

  private var installmentRowValue: String {
    guard installmentCount > 1 else { return "À vista" }
    let piece: String
    if let parsedAmount, parsedAmount > 0 {
      let parts = MoneyCardInstallment.splitTotal(parsedAmount, count: installmentCount)
      piece = CurrencyFormat.brl(parts.first ?? 0)
    } else {
      piece = "\(installmentCount)×"
      return piece
    }
    if let account = selectedAccount,
       let due = MoneyCardInstallment.firstInvoiceDueLabel(purchase: occurredOn, account: account)
    {
      return "\(installmentCount)× \(piece) · 1ª \(due)"
    }
    return "\(installmentCount)× \(piece)"
  }

  private var canSave: Bool {
    guard let parsedAmount, parsedAmount > 0 else { return false }
    if kind == .transfer {
      return fromAccount?.kind != .credit
        && toAccount?.kind != .credit
        && fromAccountId != toAccountId
    }
    return selectedAccount != nil
  }

  var body: some View {
    let c = theme.colors
    NavigationStack {
      List {
        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              MoneySheetSelectRow(
                label: "Tipo",
                value: kind.typeLabel
              ) { rect in
                showTypeMenu(anchor: rect)
              }
              SettingsCardDivider(leadingPadding: 14)
              MoneySheetFieldRow(
                label: "Quanto",
                text: $amountText,
                placeholder: "0,00",
                keyboard: .decimalPad
              )
              SettingsCardDivider(leadingPadding: 14)
              MoneySheetFieldRow(
                label: "O quê",
                text: $note,
                placeholder: "Opcional"
              )
              SettingsCardDivider(leadingPadding: 14)
              MoneySheetSelectRow(
                label: "Quando",
                value: MoneyCalendar.dayLabel(for: occurredOn)
              ) { _ in
                showDatePicker = true
              }
              SettingsCardDivider(leadingPadding: 14)
              if kind == .transfer {
                MoneySheetSelectRow(
                  label: "Saiu de",
                  value: fromAccount.map { MoneyStore.shared.displayName(for: $0) } ?? "Conta"
                ) { rect in
                  showTransferAccountMenu(anchor: rect, pickingFrom: true)
                }
                SettingsCardDivider(leadingPadding: 14)
                MoneySheetSelectRow(
                  label: "Entrou em",
                  value: toAccount.map { MoneyStore.shared.displayName(for: $0) } ?? "Conta"
                ) { rect in
                  showTransferAccountMenu(anchor: rect, pickingFrom: false)
                }
              } else {
                MoneySheetSelectRow(
                  label: kind == .income ? "Entrou em" : "Saiu de",
                  value: selectedAccount.map { MoneyStore.shared.displayName(for: $0) } ?? "Conta"
                ) { rect in
                  showAccountMenu(anchor: rect)
                }
                if showsInstallments {
                  SettingsCardDivider(leadingPadding: 14)
                  MoneySheetSelectRow(
                    label: "Parcelas",
                    value: installmentRowValue
                  ) { rect in
                    showInstallmentMenu(anchor: rect)
                  }
                }
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .settingsListCardRow(top: 8, bottom: 8)
        }
      }
      .settingsDrillDownList(background: c.background)
      .listSectionSpacing(16)
      .popoverHostScope()
      .navigationTitle(sheetTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        let isolate = GlassChromePreference.prefersStaticToolbarPills()
        ToolbarItem(id: "stacked-money-move-cancel", placement: .cancellationAction) {
          StackedToolbarTextButton(title: "Cancelar") { dismiss() }
        }
        .stackedToolbarGlassIsolation(isolate)
        ToolbarItem(id: "stacked-money-move-save", placement: .confirmationAction) {
          StackedToolbarTextButton(
            title: saveTitle,
            accent: true,
            enabled: canSave
          ) {
            guard let parsedAmount, canSave else { return }
            if let editingEntry {
              onUpdate?(
                editingEntry.id,
                accountId,
                parsedAmount,
                kind == .income,
                note,
                occurredOn,
                showsInstallments ? installmentCount : 1
              )
            } else if kind == .transfer {
              onTransfer(fromAccountId, toAccountId, parsedAmount, note, occurredOn)
            } else {
              onSave(
                accountId,
                parsedAmount,
                kind == .income,
                note,
                occurredOn,
                showsInstallments ? installmentCount : 1
              )
            }
            dismiss()
          }
        }
        .stackedToolbarGlassIsolation(isolate)
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: occurredOn,
        showsTime: false,
        title: "Quando"
      ) { date, _ in
        if let date {
          occurredOn = Calendar.current.startOfDay(for: date)
        }
      }
    }
  }

  private var sheetTitle: String {
    if isEditing { return "Editar lançamento" }
    return kind == .transfer ? "Transferência" : "Lançamento"
  }

  private var saveTitle: String {
    if isEditing { return "Guardar" }
    return kind == .transfer ? "Transferir" : "Lançar"
  }

  private func showTypeMenu(anchor: CGRect) {
    var items = [
      PopoverMenuItem(
        id: "in",
        icon: Hugeicons.arrowDown01,
        label: "Entrada",
        selected: kind == .income
      ),
      PopoverMenuItem(
        id: "out",
        icon: Hugeicons.arrowUp01,
        label: "Saída",
        selected: kind == .expense
      ),
    ]
    if canTransferBetweenAccounts && !isEditing {
      items.append(
        PopoverMenuItem(
          id: "transfer",
          icon: Hugeicons.arrowDataTransferHorizontal,
          label: "Transferência",
          selected: kind == .transfer
        )
      )
    }
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      switch result {
      case "in":
        if kind == .transfer { accountId = fromAccountId }
        kind = .income
        installmentCount = 1
      case "out":
        if kind == .transfer { accountId = fromAccountId }
        kind = .expense
      case "transfer":
        if selectedAccount?.kind != .credit {
          fromAccountId = accountId
        }
        if toAccountId == fromAccountId || toAccount == nil || toAccount?.kind == .credit {
          toAccountId = transferableAccounts.first(where: { $0.id != fromAccountId })?.id ?? ""
        }
        kind = .transfer
      default:
        break
      }
    }
  }

  private func showAccountMenu(anchor: CGRect) {
    let items = accounts.map { account in
      PopoverMenuItem(
        id: account.id,
        icon: Hugeicons.money01,
        label: MoneyStore.shared.displayName(for: account),
        selected: account.id == accountId
      )
    }
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      accountId = result
      if accounts.first(where: { $0.id == result })?.kind != .credit {
        installmentCount = 1
      }
    }
  }

  private func showInstallmentMenu(anchor: CGRect) {
    var items = [
      PopoverMenuItem(
        id: "1",
        icon: Hugeicons.creditCard,
        label: "À vista",
        selected: installmentCount <= 1
      )
    ]
    items.append(
      contentsOf: MoneyCardInstallment.counts.map { count in
        let piece: String
        if let parsedAmount, parsedAmount > 0 {
          let parts = MoneyCardInstallment.splitTotal(parsedAmount, count: count)
          piece = CurrencyFormat.brl(parts.first ?? 0)
        } else {
          piece = ""
        }
        return PopoverMenuItem(
          id: "\(count)",
          icon: Hugeicons.creditCard,
          label: piece.isEmpty ? "\(count)×" : "\(count)× · \(piece)",
          selected: installmentCount == count
        )
      }
    )
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result, let value = Int(result) else { return }
      installmentCount = max(value, 1)
    }
  }

  private func showTransferAccountMenu(anchor: CGRect, pickingFrom: Bool) {
    let selectedId = pickingFrom ? fromAccountId : toAccountId
    let items = transferableAccounts.map { account in
      PopoverMenuItem(
        id: account.id,
        icon: Hugeicons.wallet01,
        label: MoneyStore.shared.displayName(for: account),
        selected: account.id == selectedId
      )
    }
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      if pickingFrom {
        fromAccountId = result
        if toAccountId == result {
          toAccountId = transferableAccounts.first(where: { $0.id != result })?.id ?? ""
        }
      } else {
        toAccountId = result
        if fromAccountId == result {
          fromAccountId = transferableAccounts.first(where: { $0.id != result })?.id ?? ""
        }
      }
    }
  }
}

struct MoneySheetFieldRow: View {
  @Environment(ThemeManager.self) private var theme
  let label: String
  @Binding var text: String
  var placeholder: String
  var keyboard: UIKeyboardType = .default

  var body: some View {
    let c = theme.colors
    HStack(alignment: .center, spacing: 12) {
      Text(label)
        .font(AppTypography.fieldLabel)
        .foregroundStyle(c.textSecondary)
        .frame(width: 88, alignment: .leading)
      TextField(placeholder, text: $text)
        .font(AppTypography.fieldInput)
        .foregroundStyle(c.textPrimary)
        .keyboardType(keyboard)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }
}

struct MoneySheetSelectRow: View {
  @Environment(ThemeManager.self) private var theme
  let label: String
  let value: String
  let action: (CGRect) -> Void

  var body: some View {
    let c = theme.colors
    AnchoredTapButton(action: { rect in
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
      )
      action(rect)
    }) {
      HStack(spacing: 12) {
        Text(label)
          .font(AppTypography.fieldLabel)
          .foregroundStyle(c.textSecondary)
          .frame(width: 88, alignment: .leading)
        Text(value)
          .font(AppTypography.fieldInput)
          .foregroundStyle(c.textPrimary)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
        DisclosureChevron()
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
  }
}
