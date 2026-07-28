import SwiftUI
import Hugeicons

// Paridade ScreenHeader + trailing options (today_screen.dart _showOptionsMenu)
struct TaskListScreenHeader: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage private var showCompleted: Bool
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue

  let title: String
  var subtitle: String?

  private var displayMode: ProjectDisplayMode {
    ProjectDisplayMode.from(displayModeRaw)
  }

  init(
    title: String,
    subtitle: String? = nil,
    showCompletedKey: String,
    showCompletedDefault: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    _showCompleted = AppStorage(wrappedValue: showCompletedDefault, showCompletedKey)
  }

  var body: some View {
    let c = theme.colors
    ScreenHeaderChrome(title: title, subtitle: subtitle) {
      // Âncora no toque via UIKit (igual Filtros/Projeto) — readAnchor no ScrollView/List
      // ficava deslocado e o menu abria longe do ⋮.
      AnchoredTapButton { rect in
        openOptionsMenu(anchor: rect)
      } label: {
        LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
          StackedIcons.icon(.more, size: 18, color: c.textPrimary)
        }
      }
      .accessibilityLabel("Opções")
    }
  }

  private func openOptionsMenu(anchor: CGRect) {
    let modeChildren = ProjectDisplayMode.allCases.map { mode in
      PopoverMenuItem(
        id: "mode_\(mode.rawValue)",
        icon: mode.menuIcon,
        label: mode.label,
        selected: displayMode == mode,
        iconColor: theme.colors.textSecondary
      )
    }
    let items = [
      PopoverMenuItem(
        id: "toggle_completed",
        icon: showCompleted ? Hugeicons.eyeOff : Hugeicons.eye,
        label: showCompleted ? "Ocultar concluídas" : "Mostrar concluídas",
        iconColor: theme.colors.textSecondary
      ),
      PopoverMenuItem(
        id: "display_mode",
        icon: displayMode.menuIcon,
        label: "Chrome da lista",
        hasArrow: true,
        iconColor: theme.colors.textSecondary,
        children: modeChildren
      ),
    ]
    presentAnchoredPopover(
      anchorRect: anchor,
      items: items,
      alignTrailing: true
    ) { result in
      guard let result else { return }
      if result == "toggle_completed" {
        showCompleted.toggle()
        return
      }
      if result.hasPrefix("mode_"),
         let mode = ProjectDisplayMode(rawValue: String(result.dropFirst("mode_".count))) {
        displayModeRaw = mode.rawValue
      }
    }
  }
}
