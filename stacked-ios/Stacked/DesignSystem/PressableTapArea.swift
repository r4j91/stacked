import SwiftUI

/// Feedback de press na área de tap sem `Button` — não bloqueia long-press do context menu (Fase E).
struct PressableTapAreaModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let action: () -> Void

  @State private var isPressed = false
  @GestureState private var dragPressed = false

  private var showPressed: Bool {
    isPressed || dragPressed
  }

  func body(content: Content) -> some View {
    content
      .scaleEffect(showPressed && !reduceMotion ? 0.985 : 1)
      .animation(AppMotion.press(reduceMotion: reduceMotion), value: showPressed)
      .contentShape(Rectangle())
      .onTapGesture(perform: action)
      .simultaneousGesture(pressGesture)
  }

  private var pressGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .updating($dragPressed) { _, state, _ in
        state = true
      }
      .onEnded { _ in
        isPressed = false
      }
  }
}

extension View {
  func pressableTapArea(action: @escaping () -> Void) -> some View {
    modifier(PressableTapAreaModifier(action: action))
  }
}
