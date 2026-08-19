import SwiftUI

struct HomeMoneySection: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = MoneyStore.shared
  var onOpen: () -> Void

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  @AppStorage(HomeMoneyRichStorage.key) private var richLayout = HomeMoneyRichStorage.defaultEnabled

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  var body: some View {
    let c = theme.colors
    let t = typeScale.metrics
    let m = sectionStyle.metrics

    Section {
      moneyRow(
        icon: .money,
        title: "A pagar este mês",
        subtitle: store.monthSubtitle,
        amount: store.monthTotal,
        highlight: store.monthCount > 0,
        position: richLayout ? .first : .only,
        colors: c,
        type: t,
        metrics: m
      )
      if richLayout {
        moneyRow(
          icon: .cashFlow,
          title: "Nas contas",
          subtitle: store.accountsSubtitle,
          amount: store.liquidBalance,
          highlight: false,
          position: .last,
          colors: c,
          type: t,
          metrics: m
        )
      }
    } header: {
      HomeSectionHeader(text: "DINHEIRO", style: sectionStyle, scale: typeScale)
        .homeSectionHeaderInsets(sectionStyle)
    }
    .task {
      await store.load()
    }
  }

  private func moneyRow(
    icon: StackedIconKey,
    title: String,
    subtitle: String,
    amount: Double,
    highlight: Bool,
    position: HomeSectionRowPosition,
    colors c: AppThemeColors,
    type t: AppTypeScaleMetrics,
    metrics m: HomeSectionMetrics
  ) -> some View {
    Button {
      HapticService.selection()
      onOpen()
    } label: {
      HStack(spacing: HomeSectionRowLayout.iconSpacing) {
        StackedIcons.image(icon)
          .font(.system(size: 20))
          .foregroundStyle(c.accent)
          .frame(width: HomeSectionRowLayout.iconWidth)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(t.rowTitleFont)
            .foregroundStyle(c.textPrimary)
            .lineLimit(1)
          Text(subtitle)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)
        }
        .layoutPriority(1)
        Spacer(minLength: 8)
        Text(CurrencyFormat.brl(amount))
          .font(t.rowCountFont)
          .monospacedDigit()
          .fontWeight(.semibold)
          .foregroundStyle(highlight ? c.accent : c.textTertiary)
          .lineLimit(1)
          .fixedSize()
      }
      .padding(.vertical, m.rowPaddingV)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .listRowInsets(m.rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(
      HomeSectionRowBackground(
        style: sectionStyle,
        position: position,
        colors: c
      )
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(title)
    .accessibilityValue("\(subtitle), \(CurrencyFormat.brl(amount))")
    .accessibilityHint("Abre a aba Dinheiro")
  }
}
