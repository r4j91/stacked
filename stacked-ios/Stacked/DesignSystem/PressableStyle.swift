import SwiftUI

/// Press state universal — escala + highlight no touch-down, spring back no release (Fase 3C).
struct PressableStyle: ButtonStyle {
  var scale: CGFloat = 0.97
  var highlightOpacity: CGFloat = 0.06
  var cornerRadius: CGFloat?
  var onPrepare: (() -> Void)?

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
      .background {
        Group {
          if configuration.isPressed {
            if let cornerRadius {
              RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(highlightOpacity))
            } else {
              Color.white.opacity(highlightOpacity)
            }
          }
        }
      }
      .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: configuration.isPressed)
      .background {
        PressPrepareObserver(isPressed: configuration.isPressed, onPrepare: onPrepare ?? {})
      }
  }
}

struct PressPrepareObserver: View {
  let isPressed: Bool
  let onPrepare: () -> Void

  var body: some View {
    Color.clear
      .onChange(of: isPressed) { _, pressed in
        if pressed { onPrepare() }
      }
  }
}
