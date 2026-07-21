import CoreGraphics
import UIKit

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
  /// Eyebrow F2/X2 (projeto · P1 acima do título).
  static let taskRowEyebrowBlock: CGFloat = 16
  static let taskRowListDivider: CGFloat = 0.5

  /// UIKIT_SCROLL_POLISH: arredonda ao grid de pixels do display.
  static func pixelSnap(_ value: CGFloat, scale: CGFloat? = nil) -> CGFloat {
    let s = scale ?? DisplayScreen.scale
    guard s > 0 else { return value }
    return ceil(value * s) / s
  }

  /// Altura exata do header da TaskRow (sem subtarefas expandidas).
  static func taskRowHeaderHeight(
    hasDescription: Bool,
    hasMeta: Bool,
    hasEyebrow: Bool = false
  ) -> CGFloat {
    var height = taskRowHeight
    if hasEyebrow { height += taskRowEyebrowBlock }
    if hasDescription { height += taskRowDescBlock }
    if hasMeta { height += taskRowMetaBlock }
    // UIKIT_SCROLL_POLISH: return height
    return pixelSnap(height)
  }

  /// Altura média de 1 subtarefa inline (título + chips) — estimativa de layout UIKit.
  static let estimatedInlineSubtaskRowHeight: CGFloat = 56
  /// Linha extra de nota sob o título (ex.: "PAGO / …").
  static let estimatedInlineSubtaskDescBlock: CGFloat = 18

  /// Espaço de layout da cell UIKit antes do 1º sizeThatFits — evita jump 0→full no recycle.
  static func estimatedUIKitTaskRowHeight(
    hasDescription: Bool,
    hasMeta: Bool,
    expandedSubtaskCount: Int,
    rowInsets: UIEdgeInsets,
    hasEyebrow: Bool = false
  ) -> CGFloat {
    var height = taskRowHeaderHeight(
      hasDescription: hasDescription,
      hasMeta: hasMeta,
      hasEyebrow: hasEyebrow
    )
    if expandedSubtaskCount > 0 {
      height += CGFloat(expandedSubtaskCount) * estimatedInlineSubtaskRowHeight + 8
    }
    height += rowInsets.top + rowInsets.bottom
    return pixelSnap(height)
  }

  /// Estimativa do painel expandido — considera notas nas subtarefas (melhor que N×56 puro).
  static func estimatedUIKitTaskRowHeight(
    task: Task,
    showProject: Bool,
    expanded: Bool,
    rowInsets: UIEdgeInsets,
    cachedHeight: CGFloat?
  ) -> CGFloat {
    if expanded, let cachedHeight, cachedHeight > 1 {
      return pixelSnap(cachedHeight)
    }
    let layout = TaskRowLayoutStorage.current
    let showsEyebrow = TaskRowLayoutStorage.showsEyebrow(
      layout: layout,
      projectName: task.project,
      showProject: showProject,
      priority: task.priority
    )
    let showsMeta = taskRowShowsMeta(
      task: task,
      showProject: showProject,
      layout: layout
    )
    guard expanded, task.hasSubtasks else {
      return estimatedUIKitTaskRowHeight(
        hasDescription: task.hasDescription,
        hasMeta: showsMeta,
        expandedSubtaskCount: 0,
        rowInsets: rowInsets,
        hasEyebrow: showsEyebrow
      )
    }
    var height = taskRowHeaderHeight(
      hasDescription: task.hasDescription,
      hasMeta: showsMeta,
      hasEyebrow: showsEyebrow
    )
    for sub in task.subtasks {
      height += estimatedInlineSubtaskRowHeight
      let desc = sub.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if !desc.isEmpty {
        height += estimatedInlineSubtaskDescBlock
      }
    }
    height += 8 + rowInsets.top + rowInsets.bottom
    return pixelSnap(height)
  }

  /// Meta line visível — em F2/X2 o projeto sobe pro eyebrow (não conta sozinho na meta).
  static func taskRowShowsMeta(
    task: Task,
    showProject: Bool,
    layout: TaskRowLayout = TaskRowLayoutStorage.current
  ) -> Bool {
    if layout.usesEyebrow {
      if layout == .x2, task.priority != nil { return true }
      if task.dueDate != nil { return true }
      if task.timeDisplay != nil { return true }
      if !task.labels.isEmpty { return true }
      if task.subtasksTotalCount > 0 { return true }
      if task.commentCount > 0 { return true }
      return false
    }
    if layout.usesTrailingTimeColumn {
      // Projeto/hora vão na coluna trailing — meta só data/tags/contador/comentários.
      return !task.labels.isEmpty
        || task.dueDate != nil
        || task.subtasksTotalCount > 0
        || task.commentCount > 0
    }
    if layout.isDense {
      let showsProject = showProject && !task.project.isEmpty && task.project != "Sem projeto"
      return showsProject
        || !task.labels.isEmpty
        || task.dueDate != nil
        || task.timeDisplay != nil
        || task.subtasksTotalCount > 0
        || task.commentCount > 0
    }
    let showsProject = showProject && !task.project.isEmpty && task.project != "Sem projeto"
    return showsProject
      || !task.labels.isEmpty
      || task.dueDate != nil
      || task.subtasksTotalCount > 0
      || task.commentCount > 0
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
