import CoreGraphics

// Paridade lib/theme/app_layout.dart (constantes mobile — sem desktop shell)
enum AppLayout {
  static let breakpointPhone: CGFloat = 600
  static let breakpointTabletWide: CGFloat = 768
  static let breakpointDesktop: CGFloat = 1024

  static let bottomNavPillHeight: CGFloat = 62
  /// Gap entre pill e home indicator — Todoist usa ~6pt (Flutter legacy: 12).
  static let bottomNavPillMargin: CGFloat = 6
  static let fabSize: CGFloat = 56
  static let fabGap: CGFloat = 10
  static let fabSideMargin: CGFloat = 14

  static let headerControlSize: CGFloat = 48
  static let headerAvatarSize: CGFloat = 40
  static let headerIconSize: CGFloat = 24

  /// Altura alvo da linha de tarefa — paridade task_tile.dart (~52–56px)
  static let taskRowHeight: CGFloat = 54
  /// PERF_FASEB2_ETAPA3: blocos extras com desc/meta em 1 linha (medidos no visual atual).
  static let taskRowDescBlock: CGFloat = 22
  static let taskRowMetaBlock: CGFloat = 26
  static let taskRowListDivider: CGFloat = 0.5

  /// Altura exata do header da TaskRow (sem subtarefas expandidas).
  static func taskRowHeaderHeight(hasDescription: Bool, hasMeta: Bool) -> CGFloat {
    var height = taskRowHeight
    if hasDescription { height += taskRowDescBlock }
    if hasMeta { height += taskRowMetaBlock }
    return height
  }

  static func tabletContentMaxWidth(screenWidth: CGFloat) -> CGFloat {
    screenWidth >= breakpointTabletWide ? 720 : 640
  }

  /// Distância do fundo físico da tela até a base do pill (home indicator + margem).
  static func navPillBottomInset(safeBottom: CGFloat) -> CGFloat {
    safeBottom + bottomNavPillMargin
  }

  /// Distância do fundo físico até a base do FAB.
  static func fabBottomInset(safeBottom: CGFloat) -> CGFloat {
    navPillBottomInset(safeBottom: safeBottom) + bottomNavPillHeight + fabGap
  }
}
