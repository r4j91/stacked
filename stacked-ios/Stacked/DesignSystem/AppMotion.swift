import SwiftUI

// Paridade lib/theme/app_motion.dart — única fonte de curvas do app (Fase 2).
enum AppMotion {
  static let fast: Duration = .milliseconds(150)
  static let normal: Duration = .milliseconds(250)
  static let slow: Duration = .milliseconds(350)

  // MARK: - Tokens base (iOS 17+ snappy/smooth/bouncy)

  /// Toques, toggles, seleção, tabs — resposta imediata estilo Todoist.
  static var snappy: Animation {
    .snappy(duration: 0.22, extraBounce: 0)
  }

  /// Aparecer/sumir de conteúdo, overlays, transições de tela.
  static var smooth: Animation {
    .smooth(duration: 0.28)
  }

  /// Personalidade contida — bounce no ícone de aba, rotação do FAB.
  static var bouncy: Animation {
    .bouncy(duration: 0.32, extraBounce: 0.1)
  }

  // MARK: - Aliases semânticos (tuning fino sobre os tokens)

  /// Navbar: indicador deslizante — snappy ligeiramente mais rápido que o token genérico.
  static var navIndicatorSpring: Animation {
    .snappy(duration: 0.24, extraBounce: 0)
  }

  /// Navbar: morph liquid — bounce um pouco maior para a bolha “esticar” na troca.
  static var navMorphSpring: Animation {
    .bouncy(duration: 0.42, extraBounce: 0.11)
  }

  /// Popover: entrada/saída — smooth curto (~150ms perceptual).
  static var popoverSpring: Animation {
    .smooth(duration: 0.22)
  }

  /// Navbar: bounce contido no ícone ao selecionar aba.
  static var iconBounceSpring: Animation {
    .bouncy(duration: 0.32, extraBounce: 0.06)
  }

  /// Feedback de press em linhas de popover.
  static var pressFeedback: Animation {
    .snappy(duration: 0.12, extraBounce: 0)
  }

  static let popoverPresentDuration: TimeInterval = 0.16
  static let popoverDismissDuration: TimeInterval = 0.12

  /// Permanência do check preenchido antes da saída da célula (Fase 3B).
  static let taskCompleteDwell: Duration = .milliseconds(300)

  // MARK: - Reduce Motion (decisão centralizada)

  static func snappy(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : snappy
  }

  static func smooth(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : smooth
  }

  static func bouncy(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : bouncy
  }

  static func navIndicator(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : navIndicatorSpring
  }

  static func navMorph(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : navMorphSpring
  }

  static func popover(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : popoverSpring
  }

  static func iconBounce(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : iconBounceSpring
  }

  static func press(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : pressFeedback
  }

  /// Tema / transições genéricas com token configurável.
  static func animation(reduceMotion: Bool, token: Animation = smooth) -> Animation? {
    reduceMotion ? nil : token
  }

  static func duration(reduceMotion: Bool, normal: Duration) -> Duration {
    reduceMotion ? .zero : normal
  }

  /// Executa bloco animado respeitando reduce motion.
  static func animate(
    _ token: Animation,
    reduceMotion: Bool,
    _ body: () -> Void
  ) {
    if reduceMotion {
      body()
    } else {
      withAnimation(token, body)
    }
  }
}

// SUBSTITUIDO_FASE2: springs manuais response/dampingFraction + animation(reduceMotion:) com easeInOut
// static let navIndicatorSpring = Animation.spring(response: 0.26, dampingFraction: 0.86)
// static let popoverSpring = Animation.spring(response: 0.22, dampingFraction: 0.88)
// static let iconBounceSpring = Animation.spring(response: 0.28, dampingFraction: 0.62)
// static func animation(reduceMotion: Bool, normal: Duration = .milliseconds(250)) -> Animation? {
//   reduceMotion ? nil : .easeInOut(duration: normal.timeInterval)
// }

private extension Duration {
  var timeInterval: TimeInterval {
    let (seconds, attoseconds) = components
    return Double(seconds) + Double(attoseconds) / 1e18
  }
}
