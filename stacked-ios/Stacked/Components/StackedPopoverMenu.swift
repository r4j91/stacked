import SwiftUI
import Hugeicons

// Paridade lib/widgets/task_context_menu.dart + anchored_select_menu.dart
struct PopoverMenuItem: Identifiable {
  let id: String
  let icon: HugeiconsAsset
  let label: String
  var destructive = false
  var hasArrow = false
  var selected = false
  var iconColor: Color?
  var children: [PopoverMenuItem]?
  var loadChildren: (() async -> [PopoverMenuItem]?)?
}

struct StackedPopoverOverlay: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let anchorRect: CGRect
  let keyboardHeight: CGFloat
  var preferAbove = false
  let rootItems: [PopoverMenuItem]
  let allowsToggle: Bool
  let onDismiss: (String?) -> Void
  let onToggle: (String) -> Void

  @State private var pageStack: [PopoverMenuPage] = []
  @State private var toggleSelections: Set<String> = []
  @State private var isPresented = false
  @State private var isDismissing = false

  var body: some View {
    ZStack {
      Color.black.opacity(PopoverStyle.scrimOpacity * (isPresented ? 1 : 0))
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { dismiss(nil) }
        .animation(AppMotion.popover(reduceMotion: reduceMotion), value: isPresented)

      menuCard
        .position(x: clampedPosition.x, y: clampedPosition.y)
        .scaleEffect(isPresented ? 1 : PopoverStyle.scaleBegin, anchor: scaleAnchor)
        .opacity(isPresented ? 1 : 0)
        .animation(AppMotion.popover(reduceMotion: reduceMotion), value: isPresented)
    }
    .onAppear {
      pageStack = [PopoverMenuPage(title: nil, items: rootItems)]
      toggleSelections = Set(rootItems.filter(\.selected).map(\.id))
      AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) { isPresented = true }
    }
  }

  private var currentPage: PopoverMenuPage { pageStack.last ?? PopoverMenuPage(title: nil, items: []) }

  private var showsAbove: Bool {
    let screen = UIScreen.main.bounds.size
    let h = menuHeight
    let keyboardTop = screen.height - keyboardHeight
    let spaceBelow = keyboardTop - anchorRect.maxY - 10
    let spaceAbove = anchorRect.minY - 60
    return preferAbove || keyboardHeight > 0 || spaceBelow < h + 8 || spaceBelow < spaceAbove
  }

  private var scaleAnchor: UnitPoint {
    showsAbove ? .bottomLeading : .topLeading
  }

  private var menuHeight: CGFloat {
    let header: CGFloat = pageStack.count > 1 ? 49 : 0
    let loading: CGFloat = currentPage.loading ? 52 : 0
    let rows = currentPage.loading ? 0 : CGFloat(currentPage.items.count) * PopoverStyle.itemHeight
    return header + loading + rows + 16
  }

  private var clampedPosition: CGPoint {
    let screen = UIScreen.main.bounds.size
    let w = PopoverStyle.menuWidth
    let h = menuHeight
    let keyboardTop = screen.height - keyboardHeight

    var left = anchorRect.minX
    left = min(max(8, left), screen.width - w - 8)

    let top: CGFloat
    if showsAbove {
      top = max(anchorRect.minY - h - 8, 60)
    } else {
      top = min(anchorRect.maxY + 4, keyboardTop - h - 10)
    }

    return CGPoint(x: left + w / 2, y: top + h / 2)
  }

  private var menuCard: some View {
    let c = theme.colors
    return LiquidGlass.popoverCard(navBarColor: c.navBar) {
      VStack(spacing: 0) {
        if pageStack.count > 1 {
          HStack(spacing: 8) {
            Button { navigateBack() } label: {
              StackedIcons.image(.arrowLeft)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(c.textSecondary)
            }
            .buttonStyle(.plain)
            Text(currentPage.title ?? "")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(c.textSecondary)
              .lineLimit(1)
            Spacer()
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          Divider().overlay(c.textTertiary.opacity(0.15))
        }

        if currentPage.loading {
          ProgressView().tint(c.accent).frame(height: 52)
        } else {
          ForEach(currentPage.items) { item in
            let isSelected = allowsToggle
              ? toggleSelections.contains(item.id)
              : item.selected
            Button { _Concurrency.Task { await tap(item) } } label: {
              HStack(spacing: 12) {
                StackedIcons.image(item.icon)
                  .font(.system(size: 16))
                  .foregroundStyle(item.iconColor ?? (item.destructive ? AppColors.priorityHigh : c.textSecondary))
                  .frame(width: 20)
                Text(item.label)
                  .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                  .foregroundStyle(item.destructive ? AppColors.priorityHigh : c.textPrimary)
                Spacer()
                if item.hasArrow {
                  StackedIcons.image(.chevronRight)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(c.textTertiary)
                } else if isSelected {
                  StackedIcons.image(.check)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(c.accent)
                }
              }
              .padding(.horizontal, 14)
              .frame(height: PopoverStyle.itemHeight)
              .background(isSelected && !allowsToggle ? c.accent.opacity(0.1) : Color.clear)
              .contentShape(Rectangle())
            }
            .buttonStyle(PopoverRowButtonStyle())
          }
        }
      }
      .frame(width: PopoverStyle.menuWidth)
    }
    // SUBSTITUIDO_FASE1: .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
    .id(pageStack.count)
    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .leading)))
  }

  private func tap(_ item: PopoverMenuItem) async {
    if let children = item.children {
      HapticService.selection()
      AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) {
        pageStack.append(PopoverMenuPage(title: item.label, items: children))
      }
      return
    }
    if let loader = item.loadChildren {
      HapticService.selection()
      AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) {
        pageStack.append(PopoverMenuPage(title: item.label, items: [], loading: true))
      }
      let loaded = await loader()
      guard !_Concurrency.Task.isCancelled else { return }
      AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) {
        if let loaded, !loaded.isEmpty {
          pageStack[pageStack.count - 1] = PopoverMenuPage(title: item.label, items: loaded)
        } else {
          pageStack.removeLast()
          dismiss(item.id)
        }
      }
      return
    }
    if allowsToggle {
      HapticService.selection()
      if toggleSelections.contains(item.id) {
        toggleSelections.remove(item.id)
      } else {
        toggleSelections.insert(item.id)
      }
      onToggle(item.id)
      return
    }
    if item.destructive { HapticService.warning() } else { HapticService.selection() }
    dismiss(item.id)
  }

  private func navigateBack() {
    guard pageStack.count > 1 else { return }
    HapticService.selection()
    AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) {
      pageStack.removeLast()
    }
  }

  private func dismiss(_ value: String?) {
    guard !isDismissing else { return }
    isDismissing = true
    if reduceMotion {
      onDismiss(value)
      return
    }
    AppMotion.animate(AppMotion.popoverSpring, reduceMotion: reduceMotion) { isPresented = false }
    DispatchQueue.main.asyncAfter(deadline: .now() + AppMotion.popoverDismissDuration) {
      onDismiss(value)
    }
  }
}

private struct PopoverRowButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Color.white.opacity(0.06) : Color.clear)
      // SUBSTITUIDO_FASE2: .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
      .animation(AppMotion.press(reduceMotion: reduceMotion), value: configuration.isPressed)
  }
}

private struct PopoverMenuPage {
  var title: String?
  var items: [PopoverMenuItem]
  var loading = false
}

private struct AnchorKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

/// Botão que passa o frame global no toque (GeometryReader síncrono no overlay).
struct AnchoredTapButton<Label: View>: View {
  let action: (CGRect) -> Void
  @ViewBuilder let label: () -> Label

  var body: some View {
    label()
      .overlay {
        GeometryReader { geo in
          Button {
            action(geo.frame(in: .global))
          } label: {
            Color.clear.contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
  }
}

struct StackedPopoverModifier: ViewModifier {
  @Binding var isPresented: Bool
  let anchor: CGPoint
  let items: [PopoverMenuItem]
  let onSelect: (String?) -> Void

  func body(content: Content) -> some View {
    content.overlay {
      if isPresented {
        StackedPopoverOverlay(
          anchorRect: CGRect(x: anchor.x - 22, y: anchor.y - 22, width: 44, height: 44),
          keyboardHeight: 0,
          rootItems: items,
          allowsToggle: false,
          onDismiss: { value in
            isPresented = false
            onSelect(value)
          },
          onToggle: { _ in }
        )
        .environment(ThemeManager.shared)
        .zIndex(999)
      }
    }
  }
}

extension View {
  func stackedPopover(
    isPresented: Binding<Bool>,
    anchor: CGPoint,
    items: [PopoverMenuItem],
    onSelect: @escaping (String?) -> Void
  ) -> some View {
    modifier(StackedPopoverModifier(isPresented: isPresented, anchor: anchor, items: items, onSelect: onSelect))
  }

  func readAnchor(_ anchor: Binding<CGRect>) -> some View {
    background(
      GeometryReader { geo in
        Color.clear
          .preference(key: AnchorKey.self, value: geo.frame(in: .global))
      }
    )
    .onPreferenceChange(AnchorKey.self) { anchor.wrappedValue = $0 }
  }
}

@MainActor
func presentAnchoredPopover(
  anchorRect: @autoclosure @escaping () -> CGRect,
  items: [PopoverMenuItem],
  allowsToggle: Bool = false,
  preferAbove: Bool = false,
  onSelect: @escaping (String?) -> Void
) {
  func fire(with rect: CGRect) {
    PopoverPresenter.shared.present(
      anchorRect: rect,
      items: items,
      allowsToggle: allowsToggle,
      preferAbove: preferAbove,
      onSelect: onSelect
    )
  }

  DispatchQueue.main.async {
    let rect = anchorRect()
    if rect.isValidAnchor {
      fire(with: rect)
    } else {
      DispatchQueue.main.async {
        fire(with: anchorRect())
      }
    }
  }
}
