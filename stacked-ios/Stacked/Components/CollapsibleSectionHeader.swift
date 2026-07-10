import SwiftUI
import Hugeicons

/// Header colapsável para seções de projeto — chevron e hit target iguais ao expand de subtarefas.
struct CollapsibleSectionHeader: View {
  @Environment(ThemeManager.self) private var theme

  let title: String
  let count: Int
  let expanded: Bool
  let onToggle: () -> Void
  var section: ProjectSection?
  var onRename: ((ProjectSection) -> Void)?
  var onDelete: ((ProjectSection) -> Void)?

  var body: some View {
    let c = theme.colors
    let showsMenu = section != nil && (onRename != nil || onDelete != nil)

    HStack(spacing: 0) {
      Button {
        HapticService.selection()
        onToggle()
      } label: {
        HStack(spacing: 0) {
          SubtaskExpandChevron(expanded: expanded)
            .frame(width: 44, height: 44)

          Text(title)
            .font(AppTypography.collapsibleSectionTitle)
            .foregroundStyle(c.textSecondary)
            .lineLimit(1)

          Spacer(minLength: 8)

          Text("\(count)")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(c.textTertiary)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(expanded ? "Recolher seção \(title)" : "Expandir seção \(title)")
      .accessibilityValue("\(count) \(count == 1 ? "tarefa" : "tarefas")")

      if showsMenu, let section {
        AnchoredTapButton { rect in
          openSectionMenu(section: section, anchor: rect)
        } label: {
          StackedIcons.image(.more)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(c.textTertiary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Opções da seção \(title)")
      }
    }
  }

  private func openSectionMenu(section: ProjectSection, anchor: CGRect) {
    var items: [PopoverMenuItem] = []
    if onRename != nil {
      items.append(PopoverMenuItem(id: "rename", icon: Hugeicons.edit01, label: "Renomear seção"))
    }
    if onDelete != nil {
      items.append(PopoverMenuItem(id: "delete", icon: Hugeicons.delete01, label: "Excluir seção", destructive: true))
    }
    guard !items.isEmpty else { return }

    presentAnchoredPopover(anchorRect: anchor, items: items, alignTrailing: true) { value in
      switch value {
      case "rename": onRename?(section)
      case "delete": onDelete?(section)
      default: break
      }
    }
  }
}

enum ProjectSectionCollapse {
  static let uncategorizedId = "__uncategorized__"
}
