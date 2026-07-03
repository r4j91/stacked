import SwiftUI
import Hugeicons

// Paridade ScreenHeader + trailing options (today_screen.dart _showOptionsMenu)
struct TaskListScreenHeader: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage("show_completed_tasks") private var showCompleted = false

  let title: String
  var subtitle: String?

  @State private var optionsAnchor: CGRect = .zero

  var body: some View {
    ScreenHeaderChrome(title: title, subtitle: subtitle) {
      Button(action: openOptionsMenu) {
        StackedIcons.icon(.more, size: 20, color: theme.colors.textSecondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(PressableStyle(cornerRadius: 10))
      .readAnchor($optionsAnchor)
      .accessibilityLabel("Opções")
    }
  }

  private func openOptionsMenu() {
    let items = [
      PopoverMenuItem(
        id: "toggle_completed",
        icon: showCompleted ? Hugeicons.eyeOff : Hugeicons.eye,
        label: showCompleted ? "Ocultar concluídas" : "Mostrar concluídas",
        iconColor: theme.colors.textSecondary
      ),
    ]
    presentAnchoredPopover(anchorRect: optionsAnchor, items: items) { result in
      guard result == "toggle_completed" else { return }
      showCompleted.toggle()
    }
  }
}
