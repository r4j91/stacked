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

  /// Espaço acima do sheet para o menu nascer acima da âncora (fora do clip do painel).
  private var expansionTop: CGFloat {
    coordinateSpaceName == "quickAddSheet" ? 340 : 0
  }

  private var forcePreferAbove: Bool {
    coordinateSpaceName == "quickAddSheet"
  }

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
      // SUBSTITUIDO_FASE8A: overlay expande para cima — host local não cabe menu acima da âncora.
      .overlay {
        GeometryReader { geo in
          let w = geo.size.width
          let h = geo.size.height
          let expand = expansionTop
          PopoverOverlayHost(
            presenter: presenter,
            hostBounds: CGRect(x: 0, y: 0, width: w, height: h + expand),
            anchorYOffset: expand,
            forcePreferAbove: forcePreferAbove
          )
          .frame(width: w, height: h + expand, alignment: .bottom)
          .offset(y: -expand)
        }
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
