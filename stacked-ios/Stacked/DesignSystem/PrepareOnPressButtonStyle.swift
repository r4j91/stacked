import SwiftUI

// SUBSTITUIDO_FASE3C: PrepareOnPressButtonStyle isolado — use PressableStyle(onPrepare:) diretamente.
/// Prepara generators de háptico no touch-down (latência zero no impact).
struct PrepareOnPressButtonStyle: ButtonStyle {
  var onPrepare: () -> Void = {}

  func makeBody(configuration: Configuration) -> some View {
    PressableStyle(onPrepare: onPrepare).makeBody(configuration: configuration)
  }
}
