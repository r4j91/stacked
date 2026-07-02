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
    let c = theme.colors

    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(AppTypography.screenTitle)
          .foregroundStyle(c.textPrimary)
          .tracking(-0.5)
        if let subtitle {
          Text(subtitle)
            .font(.system(size: 12.5))
            .foregroundStyle(c.textSecondary)
        }
      }

      Spacer(minLength: 0)

      Button(action: openOptionsMenu) {
        StackedIcons.icon(.more, size: 20, color: c.textSecondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .readAnchor($optionsAnchor)
      .accessibilityLabel("Opções")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 8)
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
