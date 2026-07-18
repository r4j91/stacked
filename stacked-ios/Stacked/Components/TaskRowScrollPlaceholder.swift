import SwiftUI

/// PERF_FASEB3_ETAPA2 T2 — retângulo estático com a mesma altura determinística da TaskRow.
struct TaskRowScrollPlaceholder: View {
  @Environment(ThemeManager.self) private var theme

  let task: Task
  var showProject: Bool = true
  var style: TaskRowStyle = .card

  var body: some View {
    let c = theme.colors
    let layout = TaskRowLayoutStorage.current
    let height = AppLayout.taskRowHeaderHeight(
      hasDescription: task.hasDescription,
      hasMeta: AppLayout.taskRowShowsMeta(task: task, showProject: showProject, layout: layout),
      hasEyebrow: TaskRowLayoutStorage.showsEyebrow(
        layout: layout,
        projectName: showProject ? task.project : nil,
        showProject: showProject,
        priority: task.priority
      )
    )
    RoundedRectangle(cornerRadius: style.isCardFamily ? 12 : 0)
      .fill(style == .cardLight ? c.surface.opacity(0.72) : c.surface)
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .overlay(alignment: .leading) {
        RoundedRectangle(cornerRadius: 2)
          .fill(c.textTertiary.opacity(0.22))
          .frame(width: 120, height: 12)
          .padding(.leading, 46)
      }
      .accessibilityHidden(true)
  }
}
