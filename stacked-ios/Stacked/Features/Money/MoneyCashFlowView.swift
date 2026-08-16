import SwiftUI

/// Fluxo de caixa do mês civil — visão mensal ou por semanas (segunda a domingo).
struct MoneyCashFlowView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var store = MoneyStore.shared
  @State private var mode: Mode = .month
  @State private var cardsExpanded = false

  let monthId: String

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private var report: MoneyCashFlowReport? {
    store.cashFlow(monthId: monthId)
  }

  enum Mode: String, CaseIterable, Identifiable {
    case month
    case weeks

    var id: String { rawValue }

    var label: String {
      switch self {
      case .month: "Mês"
      case .weeks: "Semanas"
      }
    }
  }

  var body: some View {
    let c = theme.colors
    Group {
      if let report {
        List {
          Section {
            summaryCard(report)
          }
          Section {
            Picker("Visualização", selection: $mode) {
              ForEach(Mode.allCases) { item in
                Text(item.label).tag(item)
              }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
          if mode == .month {
            monthSections(report)
          } else {
            weekSections(report)
          }
          if !report.cardLines.isEmpty {
            cardSection(report)
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
      } else {
        EmptyStateView(
          illustration: .searchEmpty,
          title: "Fluxo indisponível",
          subtitle: "Este período não tem mês civil para montar o caixa"
        )
        .stackedStandaloneEmptyState()
      }
    }
    .stackedTabletCentered()
    .stackedThemeBackground(theme)
    .navigationTitle("Fluxo de caixa")
    .navigationBarTitleDisplayMode(.inline)
    .stackedAdaptiveDrillDownBack()
    .toolbar {
      let isolate = GlassChromePreference.prefersStaticToolbarPills()
      ToolbarItem(id: "stacked-cashflow-pdf", placement: .topBarTrailing) {
        StackedToolbarTextButton(title: "PDF", accent: true) {
          exportPDF()
        }
      }
      .stackedToolbarGlassIsolation(isolate)
    }
    .task { await store.load() }
  }

  // MARK: - Summary

  @ViewBuilder
  private func summaryCard(_ report: MoneyCashFlowReport) -> some View {
    let c = theme.colors
    let radius = max(sectionStyle.metrics.cornerRadius, 14)
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text(report.title)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
          Text(resultLabel(report))
            .font(AppTypography.screenGreeting)
            .monospacedDigit()
            .foregroundStyle(resultColor(report, colors: c))
        }
        Spacer(minLength: 8)
        Text(report.isNegativeProjected ? "Negativo" : "Positivo")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(resultColor(report, colors: c))
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(
            Capsule().fill(resultColor(report, colors: c).opacity(0.14))
          )
      }

      summaryGrid(report, colors: c)

      if report.projectedOut > 0 {
        Text("Inclui \(CurrencyFormat.brl(report.projectedOut)) ainda a sair (a pagar e faturas).")
          .font(.system(size: 12.5))
          .foregroundStyle(c.textTertiary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(c.surface)
    }
    .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 4, trailing: 18))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func summaryGrid(_ report: MoneyCashFlowReport, colors c: AppThemeColors) -> some View {
    VStack(spacing: 10) {
      summaryRow("Saldo inicial", CurrencyFormat.brl(report.opening), colors: c)
      summaryRow("Entradas", "+\(CurrencyFormat.brl(report.income))", accent: true, colors: c)
      summaryRow("Saídas", "−\(CurrencyFormat.brl(report.expense))", colors: c)
      if abs(report.transferNet) > 0.005 {
        summaryRow("Transferências", signed(report.transferNet), colors: c)
      }
      if report.projectedOut > 0 {
        summaryRow("A sair (projetado)", "−\(CurrencyFormat.brl(report.projectedOut))", colors: c)
      }
      Rectangle()
        .fill(c.textPrimary.opacity(0.08))
        .frame(height: 0.5)
      summaryRow(
        "Caixa realizado",
        CurrencyFormat.brl(report.closingRealized),
        emphasize: true,
        tint: report.isNegativeRealized ? AppColors.dateOverdue : c.textPrimary,
        colors: c
      )
      summaryRow(
        "Caixa projetado",
        CurrencyFormat.brl(report.closingProjected),
        emphasize: true,
        tint: resultColor(report, colors: c),
        colors: c
      )
    }
  }

  private func summaryRow(
    _ label: String,
    _ value: String,
    accent: Bool = false,
    emphasize: Bool = false,
    tint: Color? = nil,
    colors c: AppThemeColors
  ) -> some View {
    HStack {
      Text(label)
        .font(.system(size: emphasize ? 14 : 13, weight: emphasize ? .semibold : .regular))
        .foregroundStyle(emphasize ? c.textPrimary : c.textSecondary)
      Spacer()
      Text(value)
        .font(.system(size: emphasize ? 15 : 13.5, weight: emphasize ? .semibold : .medium))
        .monospacedDigit()
        .foregroundStyle(tint ?? (accent ? c.accent : c.textPrimary))
    }
  }

  // MARK: - Month list

  @ViewBuilder
  private func monthSections(_ report: MoneyCashFlowReport) -> some View {
    let cash = report.cashLines
    Section {
      if cash.isEmpty {
        hintRow("Nenhum movimento de caixa neste mês")
      } else {
        runningList(cash, opening: report.opening)
      }
    } header: {
      sectionHeader("MOVIMENTOS")
    }
  }

  // MARK: - Weeks

  @ViewBuilder
  private func weekSections(_ report: MoneyCashFlowReport) -> some View {
    ForEach(report.weeks) { week in
      Section {
        weekSummary(week)
        if week.lines.filter(\.affectsCash).isEmpty {
          hintRow("Sem movimentos nesta semana")
        } else {
          runningList(week.lines.filter(\.affectsCash), opening: week.opening)
        }
      } header: {
        sectionHeader("\(week.title.uppercased()) · \(week.rangeLabel.uppercased())")
      }
    }
  }

  private func weekSummary(_ week: MoneyCashFlowWeek) -> some View {
    let c = theme.colors
    let radius = max(sectionStyle.metrics.cornerRadius, 12)
    return HStack(spacing: 12) {
      weekStat("Início", CurrencyFormat.brl(week.opening), colors: c)
      weekStat("Entradas", "+\(CurrencyFormat.brl(week.income))", accent: true, colors: c)
      weekStat(
        "Saídas",
        "−\(CurrencyFormat.brl(week.expense + week.projectedOut))",
        colors: c
      )
      weekStat(
        "Fim",
        CurrencyFormat.brl(week.closing),
        tint: week.isNegative ? AppColors.dateOverdue : c.accent,
        colors: c
      )
    }
    .padding(12)
    .background {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(c.surface)
    }
    .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 6, trailing: 18))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func weekStat(
    _ label: String,
    _ value: String,
    accent: Bool = false,
    tint: Color? = nil,
    colors c: AppThemeColors
  ) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(label)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(c.textTertiary)
        .tracking(0.3)
      Text(value)
        .font(.system(size: 12, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(tint ?? (accent ? c.accent : c.textPrimary))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Card purchases (acordeão — fora do caixa)

  @ViewBuilder
  private func cardSection(_ report: MoneyCashFlowReport) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let radius = max(sectionStyle.metrics.cornerRadius, 14)
    let count = report.cardLines.count
    let subtitle = count == 1 ? "1 lançamento" : "\(count) lançamentos"

    Section {
      VStack(spacing: 0) {
        Button {
          HapticService.selection()
          withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.86)) {
            cardsExpanded.toggle()
          }
        } label: {
          HStack(spacing: HomeSectionRowLayout.iconSpacing) {
            SubtaskExpandChevron(expanded: cardsExpanded, size: 12, taskId: "cashflow-cards")
              .frame(width: HomeSectionRowLayout.iconWidth)
            VStack(alignment: .leading, spacing: 2) {
              Text("Compras no cartão")
                .font(t.rowTitleFont)
                .fontWeight(.semibold)
                .foregroundStyle(c.textPrimary)
                .lineLimit(1)
              Text("\(subtitle) · não sai do caixa")
                .font(.system(size: 12.5))
                .foregroundStyle(c.textTertiary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormat.brl(report.cardPurchases))
              .font(t.rowTitleFont)
              .fontWeight(.semibold)
              .monospacedDigit()
              .foregroundStyle(c.textPrimary)
              .lineLimit(1)
              .fixedSize()
          }
          .padding(.vertical, sectionStyle.metrics.rowPaddingV)
          .padding(.horizontal, 12)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cardsExpanded ? "Recolher compras no cartão" : "Expandir compras no cartão")
        .accessibilityValue("\(subtitle), \(CurrencyFormat.brl(report.cardPurchases))")
        .accessibilityHint("Toque para ver os lançamentos do cartão")

        SubtaskExpandReveal(
          expanded: cardsExpanded,
          reduceMotion: reduceMotion,
          contentRevision: count,
          stabilizeSelfSizingParent: true,
          panelFill: c.surface
        ) {
          VStack(spacing: 0) {
            ForEach(report.cardLines) { line in
              Rectangle()
                .fill(c.textPrimary.opacity(TaskExpandDividerStyle.cardLightStrokeAlpha))
                .frame(height: TaskExpandDividerStyle.listHairlineThickness)
                .padding(.leading, 12 + HomeSectionRowLayout.iconWidth + HomeSectionRowLayout.iconSpacing)
              cardPurchaseRow(line)
            }
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
    } header: {
      sectionHeader("CARTÃO (FORA DO CAIXA)")
    }
  }

  private func cardPurchaseRow(_ line: MoneyCashFlowLine) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    return HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(line.title)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
          .lineLimit(2)
        HStack(spacing: 6) {
          Text(line.dayLabel)
            .font(.system(size: 12.5))
            .foregroundStyle(c.textTertiary)
          if let subtitle = line.subtitle?
            .replacingOccurrences(of: " · não sai do caixa", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines),
             !subtitle.isEmpty
          {
            Text(subtitle)
              .font(.system(size: 12.5))
              .foregroundStyle(c.textTertiary)
              .lineLimit(1)
          }
        }
      }
      Spacer(minLength: 8)
      Text(signed(line.amount))
        .font(.system(size: 15, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(c.textPrimary)
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .padding(.leading, HomeSectionRowLayout.iconWidth)
  }

  // MARK: - Rows

  private func runningList(_ lines: [MoneyCashFlowLine], opening: Double) -> some View {
    let rows: [(line: MoneyCashFlowLine, running: Double)] = {
      var running = opening
      return lines.map { line in
        running += line.amount
        return (line, running)
      }
    }()
    return ForEach(rows, id: \.line.id) { row in
      cashLineRow(row.line, running: row.running)
    }
  }

  private func cashLineRow(_ line: MoneyCashFlowLine, running: Double?) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let radius = max(sectionStyle.metrics.cornerRadius, 12)
    return HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(line.title)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
          .lineLimit(2)
        HStack(spacing: 6) {
          Text(line.dayLabel)
            .font(.system(size: 12.5))
            .foregroundStyle(c.textTertiary)
          Text(line.kind.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(kindColor(line, colors: c))
          if line.isProjected {
            Text("projetado")
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(c.textTertiary)
          }
        }
        if let subtitle = line.subtitle {
          Text(subtitle)
            .font(.system(size: 12.5))
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      VStack(alignment: .trailing, spacing: 2) {
        Text(signed(line.amount))
          .font(.system(size: 15, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(line.amount >= 0 ? c.accent : c.textPrimary)
        if let running {
          Text(CurrencyFormat.brl(running))
            .font(.system(size: 11.5, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(running < -0.005 ? AppColors.dateOverdue : c.textTertiary)
        }
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .background {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(c.surface)
    }
    .listRowInsets(EdgeInsets(top: 3, leading: 18, bottom: 3, trailing: 18))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func hintRow(_ text: String) -> some View {
    let c = theme.colors
    return Text(text)
      .font(.system(size: 13.5))
      .foregroundStyle(c.textTertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 10)
      .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
  }

  private func sectionHeader(_ text: String) -> some View {
    Text(text)
      .font(AppTypography.sectionLabel)
      .foregroundStyle(theme.colors.textSecondary)
      .tracking(0.2)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 4)
      .textCase(nil)
  }

  // MARK: - Helpers

  private func resultLabel(_ report: MoneyCashFlowReport) -> String {
    CurrencyFormat.brl(report.closingProjected)
  }

  private func resultColor(_ report: MoneyCashFlowReport, colors c: AppThemeColors) -> Color {
    report.isNegativeProjected ? AppColors.dateOverdue : c.accent
  }

  private func kindColor(_ line: MoneyCashFlowLine, colors c: AppThemeColors) -> Color {
    switch line.kind {
    case .income: c.accent
    case .obligation, .invoice: AppColors.dateOverdue.opacity(0.9)
    case .cardPurchase: c.textTertiary
    default: c.textSecondary
    }
  }

  private func signed(_ value: Double) -> String {
    if value >= 0 { return "+\(CurrencyFormat.brl(value))" }
    return "−\(CurrencyFormat.brl(abs(value)))"
  }

  private func exportPDF() {
    HapticService.selection()
    guard let group = store.monthGroups.first(where: { $0.id == monthId }) else { return }
    if let url = MoneyDuePDF.fileURL(for: group) {
      MoneySharePresenter.present(url)
    }
  }
}
