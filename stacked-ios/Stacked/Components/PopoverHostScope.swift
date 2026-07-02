import SwiftUI

// SUBSTITUIDO_FASE8A: âncoras no coordinateSpace nomeado do sheet (não .global).
private struct PopoverAnchorSpaceNameKey: EnvironmentKey {
  static let defaultValue: String? = nil
}

extension EnvironmentValues {
  var popoverAnchorSpaceName: String? {
    get { self[PopoverAnchorSpaceNameKey.self] }
    set { self[PopoverAnchorSpaceNameKey.self] = newValue }
  }
}

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
  let coordinateSpaceName: String

  @State private var presenter = PopoverPresenter()
  @State private var hostBounds: CGRect = .zero

  func body(content: Content) -> some View {
    content
      .coordinateSpace(name: coordinateSpaceName)
      .environment(\.popoverAnchorSpaceName, coordinateSpaceName)
      .background {
        GeometryReader { geo in
          Color.clear
            .onAppear { hostBounds = geo.frame(in: .named(coordinateSpaceName)) }
            .onChange(of: geo.frame(in: .named(coordinateSpaceName))) { _, frame in
              hostBounds = frame
            }
        }
      }
      .overlay {
        PopoverOverlayHost(presenter: presenter, hostBounds: hostBounds)
      }
      .onAppear { PopoverHostRegistry.push(presenter) }
      .onDisappear {
        presenter.dismiss()
        PopoverHostRegistry.pop(presenter)
      }
  }
}

extension View {
  func popoverHostScope(coordinateSpaceName: String = "popoverHostLocal") -> some View {
    modifier(PopoverHostScope(coordinateSpaceName: coordinateSpaceName))
  }
}
