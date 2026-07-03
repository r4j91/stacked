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

  /// Navbar: bolha sólida deslizante — paridade Flutter SpringSimulation(600, 32).
  static var navMorphSpring: Animation {
    .interpolatingSpring(stiffness: 600, damping: 32)
  }

  /// Popover: navegação interna (sub-páginas) — smooth curto.
  static var popoverSpring: Animation {
    .smooth(duration: 0.22)
  }

  /// Popover metadata — abertura com spring físico (ProMotion / 120Hz).
  static var popoverPresentSpring: Animation {
    .spring(response: 0.28, dampingFraction: 0.82)
  }

  /// Popover metadata — fechamento seco, sem bounce.
  static var popoverDismissSpring: Animation {
    .spring(response: 0.2, dampingFraction: 1.0)
  }

  // SUBSTITUIDO_POPOVER_E1: popoverPresent/Dismiss usavam snappy (0.22, bounce 0) para abrir e fechar.

  /// Navbar: bounce no ícone ao selecionar — paridade Flutter AppDurations.medium (~240ms).
  static var iconBounceSpring: Animation {
    .bouncy(duration: 0.24, extraBounce: 0.04)
  }

  /// Subtarefas inline — expand easeOutCubic (task_tile.dart ~220ms).
  static var subtaskExpandSpring: Animation {
    .timingCurve(0.215, 0.61, 0.355, 1.0, duration: 0.22)
  }

  /// Subtarefas inline — collapse easeInCubic.
  static var subtaskCollapseSpring: Animation {
    .timingCurve(0.55, 0.055, 0.675, 0.19, duration: 0.22)
  }

  /// Feedback de press em linhas de popover.
  static var pressFeedback: Animation {
    .snappy(duration: 0.12, extraBounce: 0)
  }

  static let popoverPresentDuration: TimeInterval = 0.28
  static let popoverDismissDuration: TimeInterval = 0.18

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

  static func popoverPresent(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : popoverPresentSpring
  }

  static func popoverDismiss(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : popoverDismissSpring
  }

  static func iconBounce(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : iconBounceSpring
  }

  static func subtaskExpand(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : subtaskExpandSpring
  }

  static func subtaskCollapse(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : subtaskCollapseSpring
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
