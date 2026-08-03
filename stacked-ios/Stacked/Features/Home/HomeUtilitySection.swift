import SwiftUI

/// Container de utilidades no topo da Home, no lugar do card de saudação.
/// Segue o `HomeSectionStyle` ativo — com borda, sem borda, cápsula ou solto.
struct HomeUtilitySection: View {
  @Environment(ThemeManager.self) private var theme
  var onOpenSearch: () -> Void
  var onOpenReports: () -> Void
  var onOpenFilters: () -> Void
  var onOpenLabels: () -> Void
  var onOpenNotes: () -> Void

  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  @AppStorage(HomeHeaderStyleStorage.key) private var headerStyleRaw = HomeHeaderStyleStorage.defaultRawValue

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
    // A seção só existe sem o card, então o estilo do header vale sempre aqui.
    var list: [UtilityEntry] = []
    if !HomeHeaderStyleStorage.style(from: headerStyleRaw).hidesSearchShortcut {
      list.append(UtilityEntry(icon: .search, label: "Buscar", action: onOpenSearch))
    }
    list.append(UtilityEntry(icon: .productivity, label: "Relatórios", action: onOpenReports))
    list.append(UtilityEntry(icon: .navFilters, label: "Filtros", action: onOpenFilters))
    list.append(UtilityEntry(icon: .tag, label: "Etiquetas", action: onOpenLabels))
    list.append(UtilityEntry(icon: .note, label: "Notas", action: onOpenNotes))
    return list
  }

  var body: some View {
    let rows = entries

    Section {
      ForEach(Array(rows.enumerated()), id: \.element.label) { index, entry in
        utilityRow(entry, position: .at(index: index, count: rows.count))
      }
    } header: {
      HomeSectionHeader(text: "ATALHOS", style: sectionStyle, scale: typeScale, isFirstSection: true)
        .homeSectionHeaderInsets(sectionStyle)
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
        DisclosureChevron(color: c.textSecondary)
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
