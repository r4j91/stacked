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

    Group {
      if style.isCardFamily {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(style == .cardLight ? c.surface.opacity(0.72) : c.surface)
      } else {
        // Lista: fundo transparente + skeleton leve (evita barras sólidas no cold start).
        Color.clear
          .overlay(alignment: .bottom) {
            if style.showsListHairline {
              Rectangle()
                .fill(c.textPrimary.opacity(0.04))
                .frame(height: 1)
                .padding(.leading, style == .listComfort ? 46 : 38)
            }
          }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 2)
        .fill(c.textTertiary.opacity(style.isCardFamily ? 0.22 : 0.16))
        .frame(width: 120, height: 12)
        .padding(.leading, 46)
    }
    .accessibilityHidden(true)
  }
}
