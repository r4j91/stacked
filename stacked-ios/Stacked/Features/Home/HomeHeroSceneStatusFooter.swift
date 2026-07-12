import SwiftUI

/// Rodapé em pill sobre cenas ilustradas (Jornada, Aurora).
enum HomeHeroSceneStatusFooter {
  @ViewBuilder
  static func pill(
    colors: AppThemeColors,
    isOverdue: Bool,
    statusLabel: String,
    onOpenFilter: (() -> Void)?
  ) -> some View {
    HomeHeroStatusFooter(
      presentation: .scene,
      isOverdue: isOverdue,
      statusLabel: statusLabel,
      onOpenFilter: onOpenFilter
    )
  }
}
