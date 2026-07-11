import SwiftUI

// Paridade responsive_layout.dart _FabOverlay — itens acima do FAB (sem scrim; scrim fica no shell).
struct FabActionMenuOverlay: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let safeBottom: CGFloat
  var screenWidth: CGFloat = 0
  var fabIntegratedInIsland: Bool = false
  var islandExpanded: Bool = false
  @Binding var isOpen: Bool
  var onNewTask: () -> Void
  var onNewProject: () -> Void
  var onSearch: () -> Void

  @State private var revealedStagger = -1

  private let rowHeight: CGFloat = 44
  private let rowGap: CGFloat = 12
  private let fabMenuGap: CGFloat = 14
  private let staggerStep: TimeInterval = 0.035
  private let dismissStaggerStep: TimeInterval = 0.022

  private var fabBottom: CGFloat {
    safeBottom
      + AppLayout.bottomNavPillMargin
      + AppLayout.bottomNavPillHeight
      + AppLayout.fabGap
  }

  private var menuBottomInset: CGFloat {
    if fabIntegratedInIsland {
      let pillBottom = ChromeLayout.pillMarginBottom(safeBottom: safeBottom)
      let inner = ChromeLayout.pillInnerPadding
      let pillHeight = IslandNavMetrics.pillHeight + inner * 2
      return pillBottom + pillHeight + fabMenuGap
    }
    return fabBottom + AppLayout.fabSize + fabMenuGap
  }

  private var menuTrailingInset: CGFloat {
    guard fabIntegratedInIsland, screenWidth > 0 else {
      return AppLayout.fabSideMargin
    }
    let side = AppLayout.fabSideMargin
    let inner = ChromeLayout.pillInnerPadding
    let fabCenterX = IslandNavLayout.fabSegmentCenterX(
      screenWidth: screenWidth,
      sideMargin: side,
      innerPadding: inner,
      expanded: islandExpanded,
      fabIntegrated: true
    )
    return max(AppLayout.fabSideMargin, screenWidth - fabCenterX - rowHeight / 2)
  }

  private var menuEntries: [(String, StackedIconKey, () -> Void)] {
    [
      ("Buscar", .search, { closeMenu(); onSearch() }),
      ("Novo projeto", .newProject, { closeMenu(); onNewProject() }),
      ("Nova tarefa", .newTask, { closeMenu(); onNewTask() }),
    ]
  }

  var body: some View {
    VStack(alignment: .trailing, spacing: rowGap) {
      ForEach(Array(menuEntries.enumerated()), id: \.offset) { index, entry in
        fabMenuItem(entry.0, icon: entry.1, action: entry.2)
          .opacity(itemRevealed(displayIndex: index) ? 1 : 0)
          .scaleEffect(itemRevealed(displayIndex: index) ? 1 : 0.8)
          .animation(
            reduceMotion ? nil : (revealedStagger < 0 ? AppMotion.snappy : AppMotion.bouncy),
            value: revealedStagger
          )
      }
    }
    .padding(.trailing, menuTrailingInset)
    .padding(.bottom, menuBottomInset)
    .allowsHitTesting(isOpen)
    .onAppear { syncVisibility(isOpen) }
    .onChange(of: isOpen) { _, open in
      syncVisibility(open)
    }
  }

  /// VStack top→bottom; stagger de baixo para cima (índice 2 = mais perto do FAB).
  private func itemStaggerOrder(displayIndex: Int) -> Int {
    (menuEntries.count - 1) - displayIndex
  }

  private func itemRevealed(displayIndex: Int) -> Bool {
    guard !reduceMotion else { return isOpen }
    return itemStaggerOrder(displayIndex: displayIndex) <= revealedStagger
  }

  private func closeMenu() {
    isOpen = false
    MobileChromeController.shared.closeFabMenu()
  }

  private func syncVisibility(_ open: Bool) {
    if reduceMotion {
      revealedStagger = open ? menuEntries.count - 1 : -1
      return
    }
    if open {
      revealedStagger = -1
      for step in 0..<menuEntries.count {
        let delay = Double(step) * staggerStep
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          guard isOpen else { return }
          // SUBSTITUIDO_FASE5: withAnimation(AppMotion.bouncy)
          AppMotion.animate(AppMotion.bouncy, reduceMotion: reduceMotion) {
            revealedStagger = step
          }
        }
      }
    } else {
      let count = menuEntries.count
      for step in 0..<count {
        let delay = Double(step) * dismissStaggerStep
        let target = count - 2 - step
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          guard !isOpen else { return }
          // SUBSTITUIDO_FASE5: withAnimation(AppMotion.snappy)
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            revealedStagger = target
          }
        }
      }
    }
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

// SUBSTITUIDO_FASE4B: itens estáticos sem stagger/spring na entrada
// VStack { fabMenuItem("Buscar"...); fabMenuItem("Novo projeto"...); fabMenuItem("Nova tarefa"...) }
