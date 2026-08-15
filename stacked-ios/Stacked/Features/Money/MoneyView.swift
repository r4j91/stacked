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
  @State private var accountPendingDelete: MoneyAccount?
  @State private var expandedMonthIds: Set<String> = []
  @State private var mountedMonthIds: Set<String> = []
  @State private var snapOpenIds: Set<String> = []
  @State private var didSeedExpandedMonths = false
  @State private var searchText = ""
  @Namespace private var taskDetailZoom

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private var accountRows: [(account: MoneyAccount, nested: Bool)] {
    store.accountOutline()
  }

  private var searchQuery: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var isSearching: Bool { !searchQuery.isEmpty }

  private var visibleAccountRows: [(account: MoneyAccount, nested: Bool)] {
    let rows = accountRows
    guard isSearching else { return rows }
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
    return rows.filter { keep.contains($0.account.id) }
  }

  private var visibleInstallments: [MoneyInstallmentGroup] {
    guard isSearching else { return store.installments }
    return store.installments.filter { $0.matches(searchQuery) }
  }

  private var hasSearchResults: Bool {
    !visibleAccountRows.isEmpty || !dueRows.isEmpty || !visibleInstallments.isEmpty
  }

  var body: some View {
    let c = theme.colors

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
        dueSection
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
    .stackedTabletCentered()
    .stackedThemeBackground(theme)
    .navigationTitle("Dinheiro")
    .navigationBarTitleDisplayMode(.inline)
    .searchable(
      text: $searchText,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "Conta, parcela ou mês"
    )
    .stackedAdaptiveDrillDownBack()
    .toolbar {
      let isolate = GlassChromePreference.prefersStaticToolbarPills()
      ToolbarItem(id: "stacked-money-add", placement: .topBarTrailing) {
        StackedToolbarIconButton(icon: .plus, accessibilityLabel: "Novo lançamento", accent: true) {
          if store.accounts.isEmpty {
            editingAccount = MoneyAccount(
              id: UUID().uuidString,
              name: "",
              kind: .checking,
              balance: 0
            )
          } else {
            showMovement = true
          }
        }
      }
      .stackedToolbarGlassIsolation(isolate)
    }
    .refreshable { await store.load() }
    .navigationDestination(item: $statementRoute) { route in
      MoneyAccountStatementView(accountId: route.accountId)
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

  @ViewBuilder
  private var snapshotSection: some View {
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
    let rows = dueRows
    if isSearching, rows.isEmpty {
      EmptyView()
    } else {
      Section {
        if rows.isEmpty {
          moneyHintRow("Nada com valor pendente", position: .only)
        } else {
          ForEach(rows) { row in
            switch row {
            case .month(let group, let nested):
              monthAccordion(group, nested: nested)
            case .year(let year, let months):
              yearHeaderCard(year: year, months: months)
            }
          }
        }
      } header: {
          HomeSectionHeader(text: "A PAGAR", style: sectionStyle, scale: typeScale)
            .homeSectionHeaderInsets(sectionStyle)
      }
    }
  }

  private enum DueRow: Identifiable {
    case month(MoneyMonthGroup, nested: Bool)
    case year(year: Int, months: [MoneyMonthGroup])

    var id: String {
      switch self {
      case .month(let group, _): group.id
      case .year(let year, _): "year-\(year)"
      }
    }
  }

  private var dueRows: [DueRow] {
    var rows: [DueRow] = []
    let q = searchQuery
    for cluster in store.dueOutline {
      switch cluster {
      case .month(let group):
        if !isSearching || group.matches(q) {
          rows.append(.month(group, nested: false))
        }
      case .year(let year, let months):
        let yearHit = isSearching && queryMatchesYear(year)
        let visibleMonths = isSearching
          ? (yearHit ? months : months.filter { $0.matches(q) })
          : months
        if isSearching, visibleMonths.isEmpty { continue }
        rows.append(.year(year: year, months: visibleMonths))
        let yearId = "year-\(year)"
        if expandedMonthIds.contains(yearId) || isSearching {
          for group in visibleMonths {
            rows.append(.month(group, nested: true))
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

  private func yearHeaderCard(year: Int, months: [MoneyMonthGroup]) -> some View {
    let id = "year-\(year)"
    let expanded = expandedMonthIds.contains(id) || isSearching
    let currentYear = Calendar.current.component(.year, from: Date())
    let quiet = year != currentYear && !expanded
    let monthCount = months.count
    let total = months.reduce(0.0) { $0 + $1.total }
    return moneyAccordionCard {
      accordionHeader(
        id: id,
        title: "\(year)",
        subtitle: monthCount == 1 ? "1 mês" : "\(monthCount) meses",
        total: total,
        expanded: expanded,
        emphasizeTitle: !quiet,
        highlightAmount: !quiet,
        quiet: quiet,
        menuItems: [
          PopoverMenuItem(id: "pdf", icon: Hugeicons.pdf01, label: "Gerar PDF"),
        ],
        onMenuResult: { result in
          if result == "pdf" {
            exportDuePDF(year: year, months: months)
          }
        }
      )
    }
  }

  private func monthAccordion(_ group: MoneyMonthGroup, nested: Bool) -> some View {
    let pending = visiblePendingItems(in: group)
    let completed = visibleCompletedItems(in: group)
    let searchingOpen = isSearching
    let expanded = expandedMonthIds.contains(group.id) || searchingOpen
    let mounted = mountedMonthIds.contains(group.id) || searchingOpen
    let completedExpanded = expandedMonthIds.contains(group.completedSectionId)
    let isCurrent = group.id == store.currentMonthGroupId
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
    return moneyAccordionCard(nested: nested) {
      VStack(spacing: 0) {
        accordionHeader(
          id: group.id,
          title: group.title,
          subtitle: subtitle,
          total: total,
          expanded: expanded,
          menuItems: [
            PopoverMenuItem(id: "pdf", icon: Hugeicons.pdf01, label: "Gerar PDF"),
          ],
          onMenuResult: { result in
            if result == "pdf" {
              exportDuePDF(group)
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
                dueItemRow(item)
              }
              if !completed.isEmpty {
                accordionDivider
                accordionHeader(
                  id: group.completedSectionId,
                  title: "Concluído",
                  subtitle: completed.count == 1 ? "1 item" : "\(completed.count) itens",
                  total: completed.reduce(0) { $0 + $1.valor },
                  expanded: completedExpanded
                )
                if completedExpanded {
                  ForEach(completed) { item in
                    accordionDivider
                    dueItemRow(item, completed: true)
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
      quiet: quiet
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
    .accessibilityHint(menuItems.isEmpty ? "" : "Toque para abrir. Toque e segure para opções, inclusive PDF.")
  }

  private func accordionHeaderLabel(
    id: String,
    title: String,
    subtitle: String,
    total: Double,
    expanded: Bool,
    emphasizeTitle: Bool,
    highlightAmount: Bool,
    quiet: Bool
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
      Text(CurrencyFormat.brl(total))
        .font(t.rowCountFont)
        .monospacedDigit()
        .fontWeight(.semibold)
        .foregroundStyle(highlightAmount ? c.accent : c.textTertiary)
        .lineLimit(1)
        .fixedSize()
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())
  }

  private func exportDuePDF(_ group: MoneyMonthGroup) {
    HapticService.selection()
    if let url = MoneyDuePDF.fileURL(for: group) {
      MoneySharePresenter.present(url)
    }
  }

  private func exportDuePDF(year: Int, months: [MoneyMonthGroup]) {
    HapticService.selection()
    if let url = MoneyDuePDF.fileURL(year: year, months: months) {
      MoneySharePresenter.present(url)
    }
  }

  private func dueItemRow(_ item: MoneyDueItem, completed: Bool = false) -> some View {
    let overdue = !completed && item.isOverdue
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
        overdue: overdue
      )
      .padding(.horizontal, 12)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .accessibilityValue(
      overdue
        ? "\(item.dueLabel), atrasado, \(CurrencyFormat.brl(item.valor))"
        : "\(item.subtitle), \(CurrencyFormat.brl(item.valor))"
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
    @ViewBuilder content: () -> Content
  ) -> some View {
    let c = theme.colors
    let radius = max(sectionStyle.metrics.cornerRadius, 14)
    let leading: CGFloat = nested ? 18 + HomeSectionRowLayout.iconWidth : 18
    return content()
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(c.surface)
      }
      .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
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
    if store.dueOutline.contains(where: { $0.id == yearId }) {
      initial.insert(yearId)
    }
    if store.monthGroups.contains(where: { $0.id == currentMonth }) {
      initial.insert(currentMonth)
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
    let rows = visibleAccountRows
    let extra = (!isSearching && rows.isEmpty) ? 1 : 0
    let addCard = (!isSearching && !store.bankAccounts().isEmpty) ? 1 : 0
    let addBank = isSearching ? 0 : 1
    let total = rows.count + extra + addCard + addBank
    if isSearching, rows.isEmpty {
      EmptyView()
    } else {
    Section {
      if rows.isEmpty {
        moneyHintRow("O saldo de cada banco aparece aqui. Cartões ficam dentro do banco.", position: .first)
      }
      ForEach(Array(rows.enumerated()), id: \.element.account.id) { index, row in
        SubtaskTitlePressArea(
          onTap: {
            HapticService.selection()
            statementRoute = MoneyStatementRoute(accountId: row.account.id)
          },
          onDelete: {
            accountPendingDelete = row.account
          },
          deleteLabel: row.account.kind == .credit ? "Excluir cartão" : "Excluir conta",
          extraItems: row.account.kind == .credit ? [] : [
            PopoverMenuItem(
              id: "new-card",
              icon: Hugeicons.creditCard,
              label: "Novo cartão"
            )
          ],
          onMenuResult: { result in
            if result == "new-card" {
              editingAccount = newCardDraft(under: row.account)
            }
          }
        ) {
          moneyValueRow(
            title: row.account.name,
            subtitle: cardSubtitle(row.account),
            amount: row.account.displayAmount,
            highlight: row.account.highlightsAmount,
            usage: store.limitUsage(for: row.account) ?? row.account.limitUsage
          )
          .padding(.leading, row.nested ? HomeSectionRowLayout.iconWidth : 0)
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
      if addCard == 1 {
        Button {
          HapticService.selection()
          editingAccount = newCardDraft(under: store.bankAccounts().first)
        } label: {
          HStack(spacing: HomeSectionRowLayout.iconSpacing) {
            StackedIcons.image(.plus)
              .font(.system(size: 18))
              .foregroundStyle(c.accent)
              .frame(width: HomeSectionRowLayout.iconWidth)
            Text("Novo cartão")
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
            position: .at(index: rows.count + extra, count: total),
            colors: c
          )
        )
      }
      if addBank == 1 {
        Button {
          HapticService.selection()
          editingAccount = MoneyAccount(
            id: UUID().uuidString,
            name: "",
            kind: .checking,
            balance: 0
          )
        } label: {
          HStack(spacing: HomeSectionRowLayout.iconSpacing) {
            StackedIcons.image(.plus)
              .font(.system(size: 18))
              .foregroundStyle(c.accent)
              .frame(width: HomeSectionRowLayout.iconWidth)
            Text("Nova conta bancária")
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
            position: .at(index: rows.count + extra + addCard, count: total),
            colors: c
          )
        )
      }
    } header: {
      HomeSectionHeader(
        text: "CONTAS",
        style: sectionStyle,
        scale: typeScale,
        isFirstSection: !store.showsHubSnapshot || isSearching
      )
        .homeSectionHeaderInsets(sectionStyle)
    }
    }
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

  private func cardSubtitle(_ account: MoneyAccount) -> String {
    var parts = [account.kindCaption]
    let remaining = store.futureInstallmentCount(for: account.id)
    if remaining > 0 {
      parts.append("\(remaining)×")
    }
    return parts.joined(separator: " · ")
  }

  private func moneyValueRow(
    title: String,
    subtitle: String,
    amount: Double,
    highlight: Bool,
    dimmed: Bool = false,
    usage: Double? = nil,
    overdue: Bool = false
  ) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: HomeSectionRowLayout.iconSpacing) {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(t.rowTitleFont)
            .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
            .lineLimit(1)
          if overdue {
            overdueSubtitle(subtitle, colors: c)
          } else if !subtitle.isEmpty {
            Text(subtitle)
              .font(AppTypography.screenSubtitle)
              .foregroundStyle(c.textTertiary)
              .lineLimit(1)
          }
        }
        .layoutPriority(1)
        Spacer(minLength: 8)
        Text(CurrencyFormat.brl(amount))
          .font(t.rowCountFont)
          .monospacedDigit()
          .fontWeight(highlight ? .semibold : .regular)
          .foregroundStyle(highlight ? c.accent : c.textSecondary)
          .lineLimit(1)
          .fixedSize()
      }
      if let usage {
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(c.surfaceVariant)
            Capsule()
              .fill(c.accent)
              .frame(width: max(4, geo.size.width * usage))
          }
        }
        .frame(height: 3)
      }
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
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
    let banks = MoneyStore.shared.bankAccounts(excluding: account.id)
    let initialParent = account.parentAccountId ?? (account.kind == .credit ? banks.first?.id : nil)
    _parentAccountId = State(initialValue: initialParent)
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
      if selected == .credit, parentAccountId == nil {
        parentAccountId = moneyStore.bankAccounts(excluding: accountId).first?.id
      }
    }
  }

  private var parentBankName: String {
    if let parentAccountId, let bank = moneyStore.account(id: parentAccountId) {
      return bank.name
    }
    return "Nenhum"
  }

  private func showBankMenu(anchor: CGRect) {
    let banks = moneyStore.bankAccounts(excluding: accountId)
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(
        id: "none",
        icon: Hugeicons.cancel01,
        label: "Nenhum",
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
