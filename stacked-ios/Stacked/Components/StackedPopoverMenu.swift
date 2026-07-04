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
  var hostBounds: CGRect = UIScreen.main.bounds
  /// Offset da âncora no espaço do host expandido (popover escopado em sheet).
  var anchorYOffset: CGFloat = 0
  /// Host de sheet: força abertura acima da âncora (teclado ocupa tudo abaixo).
  var forcePreferAbove: Bool = false
  /// Fundo sólido (Quick Add) — evita bandas do glass sobre scrim + painel.
  var opaqueSurface: Bool = false
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
      // Scrim no valor final — sem fade-in (só scale+opacity do card animam).
      Color.black.opacity(PopoverStyle.scrimOpacity * (isPresented ? 1 : 0))
        .animation(.none, value: isPresented)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { dismiss(nil) }
      // SUBSTITUIDO_POPOVER_E1: .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: isPresented)

      popoverCardLayer
        .position(x: clampedPosition.x, y: clampedPosition.y)
      // SUBSTITUIDO_POPOVER_E2: menuCard inteiro (glass+shadow+conteúdo) recebia scale+opacity.
    }
    .onAppear {
      pageStack = [PopoverMenuPage(title: nil, items: rootItems)]
      toggleSelections = Set(rootItems.filter(\.selected).map(\.id))
      // SUBSTITUIDO_POPOVER_E1: AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { isPresented = true }
      AppMotion.animate(AppMotion.popoverPresentSpring, reduceMotion: reduceMotion) { isPresented = true }
    }
  }

  private var currentPage: PopoverMenuPage { pageStack.last ?? PopoverMenuPage(title: nil, items: []) }

  private var localAnchorRect: CGRect {
    var rect = anchorRect
    if anchorYOffset > 0 {
      rect = rect.offsetBy(dx: 0, dy: anchorYOffset)
    }
    guard hostBounds.width > 1, hostBounds.height > 1 else { return rect }
    return rect.offsetBy(dx: -hostBounds.minX, dy: -hostBounds.minY)
  }

  private var layoutSize: CGSize {
    hostBounds.width > 1 ? hostBounds.size : UIScreen.main.bounds.size
  }

  /// Quick Add: âncora e host no mesmo espaço local do sheet — não aplicar clamp de teclado em coords de tela.
  private var usesLocalHostCoordinates: Bool {
    forcePreferAbove && hostBounds.height > 1 && hostBounds.height < ScreenMetrics.bounds.height * 0.45
  }

  private var showsAbove: Bool {
    if forcePreferAbove { return true }
    let anchor = localAnchorRect
    let screen = layoutSize
    let h = menuHeight
    let keyboardTop = screen.height - keyboardHeight
    let spaceBelow = keyboardTop - anchor.maxY - 10
    let spaceAbove = anchor.minY - topInset
    return preferAbove || keyboardHeight > 0 || spaceBelow < h + 8 || spaceBelow < spaceAbove
  }

  private var topInset: CGFloat { forcePreferAbove ? 8 : 60 }

  private var scaleAnchor: UnitPoint {
    showsAbove ? .bottomLeading : .topLeading
  }

  private var menuHeight: CGFloat {
    let header: CGFloat = pageStack.count > 1 ? 49 : 0
    let loading: CGFloat = currentPage.loading ? 52 : 0
    let rows = currentPage.loading ? 0 : CGFloat(currentPage.items.count) * PopoverStyle.itemHeight
    return header + loading + rows
  }

  private var clampedPosition: CGPoint {
    let anchor = localAnchorRect
    let screen = layoutSize
    let w = PopoverStyle.menuWidth
    let h = menuHeight
    let keyboardTop = screen.height - keyboardHeight

    var left = anchor.midX - w / 2
    left = min(max(8, left), screen.width - w - 8)

    let top: CGFloat
    if showsAbove {
      var proposed = anchor.minY - h - 6
      proposed = max(proposed, topInset)
      if keyboardHeight > 0, !usesLocalHostCoordinates {
        proposed = min(proposed, keyboardTop - h - 6)
        proposed = max(proposed, topInset)
      }
      top = proposed
    } else {
      top = min(anchor.maxY + 4, keyboardTop - h - 10)
    }

    return CGPoint(x: left + w / 2, y: top + h / 2)
  }

  // SUBSTITUIDO_POPOVER_E2: glass+stroke+shadow animavam no mesmo layer que scale+opacity.
  // cardContent.background(c.surface) / LiquidGlass.popoverCard { cardContent } recebiam scaleEffect.

  private var popoverCardLayer: some View {
    let h = menuHeight
    return ZStack {
      menuCardChrome
        .frame(width: PopoverStyle.menuWidth, height: h)
        .opacity(isPresented ? 1 : 0)
        .animation(.none, value: isPresented)

      menuCardContent
        .frame(width: PopoverStyle.menuWidth, height: h, alignment: .top)
        .scaleEffect(isPresented ? 1 : PopoverStyle.scaleBegin, anchor: scaleAnchor)
        .opacity(isPresented ? 1 : 0)
    }
    .compositingGroup()
  }

  @ViewBuilder
  private var menuCardChrome: some View {
    let c = theme.colors
    let shape = RoundedRectangle(cornerRadius: PopoverStyle.radius, style: .continuous)
    if opaqueSurface {
      shape
        .fill(c.surface)
        .overlay {
          shape.stroke(c.textTertiary.opacity(PopoverStyle.cardStrokeOpacity), lineWidth: 0.5)
        }
    } else {
      LiquidGlass.popoverCardChrome(navBarColor: c.navBar)
    }
  }

  private var menuCardContent: some View {
    let c = theme.colors
    return VStack(spacing: 0) {
        if pageStack.count > 1 {
          HStack(spacing: 8) {
            Button { navigateBack() } label: {
              StackedIcons.image(.arrowLeft)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(c.textSecondary)
            }
            .buttonStyle(.plain)
            Text(currentPage.title ?? "")
              .font(AppTypography.sectionLabel)
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
                  .font(AppTypography.popoverRowLabel)
                  .fontWeight(isSelected ? .semibold : .regular)
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
              .background(rowSelectionBackground(isSelected: isSelected, item: item))
              .contentShape(Rectangle())
            }
            .buttonStyle(PopoverRowButtonStyle())
          }
        }
      }
      .frame(width: PopoverStyle.menuWidth)
      .clipShape(RoundedRectangle(cornerRadius: PopoverStyle.radius, style: .continuous))
      .id(pageStack.count)
      .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .leading)))
  }

  /// Fundo da linha selecionada — paridade anchored_select_menu.dart (single + multi).
  private func rowSelectionBackground(isSelected: Bool, item: PopoverMenuItem) -> Color {
    guard isSelected else { return .clear }
    let c = theme.colors
    if allowsToggle {
      return (item.iconColor ?? c.accent).opacity(0.12)
    }
    return c.accent.opacity(0.14)
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
    // Fechamento instantâneo — evita fade do conteúdo enquanto o card encolhe.
    onDismiss(value)
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

/// Botão que passa o frame da âncora no toque.
struct AnchoredTapButton<Label: View>: View {
  let action: (CGRect) -> Void
  @ViewBuilder let label: () -> Label

  @Environment(\.popoverAnchorSpaceName) private var anchorSpaceName

  var body: some View {
    if anchorSpaceName != nil {
      localAnchorButton
    } else {
      screenAnchorButton
    }
  }

  private var localAnchorButton: some View {
    label()
      .overlay {
        GeometryReader { geo in
          Button {
            action(geo.frame(in: .named(anchorSpaceName!)))
          } label: {
            Color.clear.contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .buttonStyle(PressableStyle(cornerRadius: 22))
  }

  // SUBSTITUIDO_FASE8A: captura frame de tela no toque via UIKit (confiável no .sheet).
  private var screenAnchorButton: some View {
    label()
      .overlay {
        ScreenAnchorTapOverlay(onTap: action)
      }
      .buttonStyle(PressableStyle(cornerRadius: 22))
  }
}

// SUBSTITUIDO_FASE3C: overlay com Button .plain em cima do label (press invisível)
// label()
//   .overlay {
//     GeometryReader { geo in
//       Button { action(geo.frame(in: .global)) } label: { Color.clear.contentShape(Rectangle()) }
//         .buttonStyle(.plain)
//     }
//   }

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
    PopoverHostRegistry.active.present(
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
