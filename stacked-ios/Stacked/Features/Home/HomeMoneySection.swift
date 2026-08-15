import SwiftUI

struct HomeMoneySection: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = MoneyStore.shared
  var onOpen: () -> Void

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

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
      Button {
        HapticService.selection()
        onOpen()
      } label: {
        HStack(spacing: HomeSectionRowLayout.iconSpacing) {
          StackedIcons.image(.money)
            .font(.system(size: 20))
            .foregroundStyle(c.accent)
            .frame(width: HomeSectionRowLayout.iconWidth)
          VStack(alignment: .leading, spacing: 2) {
            Text("A pagar este mês")
              .font(t.rowTitleFont)
              .foregroundStyle(c.textPrimary)
              .lineLimit(1)
            Text(store.monthSubtitle)
              .font(AppTypography.screenSubtitle)
              .foregroundStyle(c.textTertiary)
              .lineLimit(1)
          }
          .layoutPriority(1)
          Spacer(minLength: 8)
          Text(CurrencyFormat.brl(store.monthTotal))
            .font(t.rowCountFont)
            .monospacedDigit()
            .fontWeight(.semibold)
            .foregroundStyle(store.monthCount > 0 ? c.accent : c.textTertiary)
            .lineLimit(1)
            .fixedSize()
          DisclosureChevron(color: c.textSecondary)
        }
        .padding(.vertical, m.rowPaddingV)
      }
      .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
      .listRowInsets(m.rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(
        HomeSectionRowBackground(
          style: sectionStyle,
          position: .only,
          colors: c
        )
      )
    } header: {
      HomeSectionHeader(text: "DINHEIRO", style: sectionStyle, scale: typeScale)
        .homeSectionHeaderInsets(sectionStyle)
    }
    .task {
      await store.load()
    }
  }
}
