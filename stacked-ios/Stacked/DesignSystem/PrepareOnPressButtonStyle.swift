import SwiftUI

/// Prepara generators de háptico no touch-down (latência zero no impact).
struct PrepareOnPressButtonStyle: ButtonStyle {
  var onPrepare: () -> Void = {}

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background {
        PressPrepareObserver(isPressed: configuration.isPressed, onPrepare: onPrepare)
      }
  }
}

private struct PressPrepareObserver: View {
  let isPressed: Bool
  let onPrepare: () -> Void

  var body: some View {
    Color.clear
      .onChange(of: isPressed) { _, pressed in
        if pressed { onPrepare() }
      }
  }
}
