import SwiftUI

/// Container de utilidades no topo da Home, no lugar do card de saudação.
/// Segue o `HomeSectionStyle` ativo — com borda, sem borda, cápsula ou solto.
struct HomeUtilitySection: View {
  @Environment(ThemeManager.self) private var theme
  var onOpenSearch: () -> Void
  var onOpenReports: () -> Void
  var onOpenFilters: () -> Void
  var onOpenLabels: () -> Void

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private struct UtilityEntry {
    let icon: StackedIconKey
    let label: String
    let action: () -> Void
  }

  private var entries: [UtilityEntry] {
    [
      UtilityEntry(icon: .search, label: "Buscar", action: onOpenSearch),
      UtilityEntry(icon: .productivity, label: "Relatórios", action: onOpenReports),
      UtilityEntry(icon: .navFilters, label: "Filtros", action: onOpenFilters),
      UtilityEntry(icon: .tag, label: "Etiquetas", action: onOpenLabels),
    ]
  }

  var body: some View {
    let rows = entries

    Section {
      Color.clear
        .frame(height: 8)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

      ForEach(Array(rows.enumerated()), id: \.element.label) { index, entry in
        utilityRow(entry, position: .at(index: index, count: rows.count))
      }
    }
  }

  private func utilityRow(_ entry: UtilityEntry, position: HomeSectionRowPosition) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let m = sectionStyle.metrics

    return Button {
      HapticService.selection()
      entry.action()
    } label: {
      HStack(spacing: HomeSectionRowLayout.iconSpacing) {
        StackedIcons.image(entry.icon)
          .font(.system(size: 20))
          .foregroundStyle(c.accent)
          .frame(width: HomeSectionRowLayout.iconWidth)
        Text(entry.label).font(t.rowTitleFont).foregroundStyle(c.textPrimary)
        Spacer()
        DisclosureChevron(color: c.textTertiary.opacity(0.7))
      }
      .padding(.vertical, m.rowPaddingV)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .listRowInsets(m.rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(
      HomeSectionRowBackground(style: sectionStyle, position: position, colors: c)
    )
  }
}
