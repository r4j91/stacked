import SwiftUI

// Paridade responsive_layout.dart _FabOverlay — posição compartilhada com MobileShell.
struct FabActionMenuOverlay: View {
  @Environment(ThemeManager.self) private var theme
  let safeBottom: CGFloat
  @Binding var isOpen: Bool
  var onNewTask: () -> Void
  var onNewProject: () -> Void
  var onSearch: () -> Void

  private let rowHeight: CGFloat = 44
  private let rowGap: CGFloat = 12
  private let fabMenuGap: CGFloat = 14

  /// Distância do fundo da tela até a base do FAB (fabBottom no Flutter).
  private var fabBottom: CGFloat {
    safeBottom
      + AppLayout.bottomNavPillMargin
      + AppLayout.bottomNavPillHeight
      + AppLayout.fabGap
  }

  private var menuBottomInset: CGFloat {
    fabBottom + AppLayout.fabSize + fabMenuGap
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Color.black.opacity(0.55)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { isOpen = false }

      VStack(alignment: .trailing, spacing: rowGap) {
        fabMenuItem("Buscar", icon: .search) {
          isOpen = false
          onSearch()
        }
        fabMenuItem("Novo projeto", icon: .newProject) {
          isOpen = false
          onNewProject()
        }
        fabMenuItem("Nova tarefa", icon: .newTask) {
          isOpen = false
          onNewTask()
        }
      }
      .padding(.trailing, AppLayout.fabSideMargin)
      .padding(.bottom, menuBottomInset)
    }
    .ignoresSafeArea()
    .allowsHitTesting(isOpen)
    .transition(.opacity)
  }

  private func fabMenuItem(_ label: String, icon: StackedIconKey, action: @escaping () -> Void) -> some View {
    let c = theme.colors
    return Button(action: action) {
      HStack(spacing: 10) {
        Text(label)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(c.textPrimary)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(c.surface)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(c.textPrimary.opacity(0.08)))

        StackedIcons.image(icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(c.accent)
          .frame(width: rowHeight, height: rowHeight)
          .background(c.surface)
          .clipShape(Circle())
          .overlay(Circle().stroke(c.textPrimary.opacity(0.08)))
      }
    }
    .buttonStyle(.plain)
  }
}
