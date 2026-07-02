import SwiftUI

// Paridade lib/theme/app_motion.dart
enum AppMotion {
  static let fast: Duration = .milliseconds(150)
  static let normal: Duration = .milliseconds(250)
  static let slow: Duration = .milliseconds(350)

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
