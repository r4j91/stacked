import SwiftUI

// Fase 7B — popovers dentro de sheets/fullScreenCover usam host local (não o overlay global).
@MainActor
enum PopoverHostRegistry {
  private static var scopeStack: [PopoverPresenter] = []

  static var active: PopoverPresenter {
    scopeStack.last ?? .shared
  }

  static func push(_ presenter: PopoverPresenter) {
    scopeStack.append(presenter)
  }

  static func pop(_ presenter: PopoverPresenter) {
    scopeStack.removeAll { $0 === presenter }
  }
}

/// Monta overlay de popover no contexto local (sheet / fullScreenCover) com âncoras no espaço do host.
struct PopoverHostScope: ViewModifier {
  @State private var presenter = PopoverPresenter()
  @State private var hostBounds: CGRect = .zero

  func body(content: Content) -> some View {
    content
      .background {
        GeometryReader { geo in
          Color.clear
            .onAppear { hostBounds = geo.frame(in: .global) }
            .onChange(of: geo.frame(in: .global)) { _, frame in
              hostBounds = frame
            }
        }
      }
      .overlay {
        PopoverOverlayHost(presenter: presenter, hostBounds: hostBounds)
      }
      .onAppear { PopoverHostRegistry.push(presenter) }
      .onDisappear { PopoverHostRegistry.pop(presenter) }
  }
}

extension View {
  func popoverHostScope() -> some View {
    modifier(PopoverHostScope())
  }
}
