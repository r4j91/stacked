import CoreGraphics

// Paridade lib/theme/app_layout.dart (constantes mobile — sem desktop shell)
enum AppLayout {
  static let breakpointPhone: CGFloat = 600
  static let breakpointTabletWide: CGFloat = 768
  static let breakpointDesktop: CGFloat = 1024

  static let bottomNavPillHeight: CGFloat = 62
  static let bottomNavPillMargin: CGFloat = 12
  static let fabSize: CGFloat = 56
  static let fabGap: CGFloat = 10
  static let fabSideMargin: CGFloat = 14

  static let headerControlSize: CGFloat = 48
  static let headerAvatarSize: CGFloat = 40
  static let headerIconSize: CGFloat = 24

  /// Altura alvo da linha de tarefa — paridade task_tile.dart (~52–56px)
  static let taskRowHeight: CGFloat = 54

  static func tabletContentMaxWidth(screenWidth: CGFloat) -> CGFloat {
    screenWidth >= breakpointTabletWide ? 720 : 640
  }
}
