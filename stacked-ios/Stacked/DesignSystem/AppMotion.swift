import SwiftUI

// Paridade lib/theme/app_motion.dart + spring do navbar Flutter (stiffness 600, damping 32)
enum AppMotion {
  static let fast: Duration = .milliseconds(150)
  static let normal: Duration = .milliseconds(250)
  static let slow: Duration = .milliseconds(350)

  /// Indicador deslizante do navbar — resposta rápida estilo Todoist.
  static let navIndicatorSpring = Animation.spring(response: 0.26, dampingFraction: 0.86)

  /// Entrada/saída de popovers ancorados (~150ms com spring).
  static let popoverSpring = Animation.spring(response: 0.22, dampingFraction: 0.88)

  /// Bounce sutil no ícone ao selecionar aba.
  static let iconBounceSpring = Animation.spring(response: 0.28, dampingFraction: 0.62)

  static let popoverPresentDuration: TimeInterval = 0.16
  static let popoverDismissDuration: TimeInterval = 0.12

  static func duration(reduceMotion: Bool, normal: Duration) -> Duration {
    reduceMotion ? .zero : normal
  }

  static func animation(reduceMotion: Bool, normal: Duration = .milliseconds(250)) -> Animation? {
    reduceMotion ? nil : .easeInOut(duration: normal.timeInterval)
  }
}

private extension Duration {
  var timeInterval: TimeInterval {
    let (seconds, attoseconds) = components
    return Double(seconds) + Double(attoseconds) / 1e18
  }
}
