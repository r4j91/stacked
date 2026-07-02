import SwiftUI

// SUBSTITUIDO_FASE8A: Quick Add usa overlay local com coords de tela; sheet nativo fica acima da AppRoot.
private struct PopoverAnchorSpaceNameKey: EnvironmentKey {
  static let defaultValue: String? = nil
}

extension EnvironmentValues {
  var popoverAnchorSpaceName: String? {
    get { self[PopoverAnchorSpaceNameKey.self] }
    set { self[PopoverAnchorSpaceNameKey.self] = newValue }
  }
}

enum PopoverOverlayPlacement {
  /// Overlay dentro do conteúdo (TaskDetail, SubtaskDetail).
  case local
  /// Quick Add: overlay dentro do sheet, coords de tela, acima do painel.
  case quickAddSheet
}

private struct ScopedPopoverHost: Identifiable {
  let id = UUID()
  let presenter: PopoverPresenter
  let placement: PopoverOverlayPlacement
}

// Fase 7B / 8A — popovers dentro de sheets usam host escopado (não o overlay global).
@MainActor
enum PopoverHostRegistry {
  private static var scopeStack: [ScopedPopoverHost] = []

  static var active: PopoverPresenter {
    scopeStack.last?.presenter ?? .shared
  }

  static func push(_ presenter: PopoverPresenter, placement: PopoverOverlayPlacement) {
    scopeStack.append(ScopedPopoverHost(presenter: presenter, placement: placement))
  }

  static func pop(_ presenter: PopoverPresenter) {
    scopeStack.removeAll { $0.presenter === presenter }
  }
}

/// Monta overlay de popover escopado ao sheet / fullScreenCover.
struct PopoverHostScope: ViewModifier {
  let coordinateSpaceName: String
  let placement: PopoverOverlayPlacement

  @State private var presenter = PopoverPresenter()

  func body(content: Content) -> some View {
    Group {
      switch placement {
      case .local:
        content
          .coordinateSpace(name: coordinateSpaceName)
          .environment(\.popoverAnchorSpaceName, coordinateSpaceName)
          .overlay {
            GeometryReader { geo in
              PopoverOverlayHost(
                presenter: presenter,
                hostBounds: geo.frame(in: .named(coordinateSpaceName))
              )
            }
          }
      case .quickAddSheet:
        content
          .environment(\.popoverAnchorSpaceName, nil)
          .overlay {
            PopoverOverlayHost(
              presenter: presenter,
              hostBounds: ScreenMetrics.bounds,
              forcePreferAbove: true
            )
            .ignoresSafeArea()
          }
      }
    }
    .onAppear { PopoverHostRegistry.push(presenter, placement: placement) }
    .onDisappear {
      presenter.dismiss()
      PopoverHostRegistry.pop(presenter)
    }
  }
}

extension View {
  func popoverHostScope(
    coordinateSpaceName: String = "popoverHostLocal",
    placement: PopoverOverlayPlacement = .local
  ) -> some View {
    modifier(PopoverHostScope(coordinateSpaceName: coordinateSpaceName, placement: placement))
  }
}
