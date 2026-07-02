import SwiftUI

// SUBSTITUIDO_FASE8A: Quick Add usa overlay na janela (acima do sheet); demais sheets usam host local.
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
  /// Overlay na janela, acima do sheet nativo (Quick Add).
  case window
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

  static var windowPresenter: PopoverPresenter? {
    scopeStack.last(where: { $0.placement == .window })?.presenter
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
      if placement == .local {
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
      } else {
        // Window: âncoras globais; overlay renderizado por WindowPopoverBridge na janela.
        content
          .environment(\.popoverAnchorSpaceName, nil)
      }
    }
    .onAppear { PopoverHostRegistry.push(presenter, placement: placement) }
    .onDisappear {
      presenter.dismiss()
      PopoverHostRegistry.pop(presenter)
    }
  }
}

/// Popover acima do sheet nativo — evita clip do container e faixa extra no painel.
struct WindowPopoverBridge: View {
  let isSheetOpen: Bool

  var body: some View {
    if isSheetOpen, let presenter = PopoverHostRegistry.windowPresenter {
      WindowPopoverBridgeContent(presenter: presenter)
    }
  }
}

private struct WindowPopoverBridgeContent: View {
  @Bindable var presenter: PopoverPresenter

  var body: some View {
    if presenter.isPresented {
      PopoverOverlayHost(
        presenter: presenter,
        hostBounds: UIScreen.main.bounds,
        forcePreferAbove: true
      )
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

  func windowPopoverBridge(isSheetOpen: Bool) -> some View {
    overlay {
      WindowPopoverBridge(isSheetOpen: isSheetOpen)
    }
  }
}
