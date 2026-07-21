import SwiftUI

/// Gutter à esquerda: trilho + nó colorido (Hoje / Em breve).
struct TimelineRailRow<Content: View>: View {
  @Environment(ThemeManager.self) private var theme

  let nodeColor: Color
  var connectsUp: Bool = true
  var connectsDown: Bool = true
  var nodeTop: CGFloat = 14
  @ViewBuilder var content: () -> Content

  private let gutterWidth: CGFloat = 16
  private let nodeSize: CGFloat = 10
  private let lineWidth: CGFloat = 2

  var body: some View {
    let c = theme.colors
    let line = c.textTertiary.opacity(0.32)

    HStack(alignment: .top, spacing: 8) {
      ZStack(alignment: .top) {
        TimelineRailLine(
          connectsUp: connectsUp,
          connectsDown: connectsDown,
          nodeTop: nodeTop,
          nodeSize: nodeSize,
          lineWidth: lineWidth,
          color: line
        )
        Circle()
          .fill(nodeColor)
          .frame(width: nodeSize, height: nodeSize)
          .overlay(
            Circle()
              .strokeBorder(c.background, lineWidth: 2)
          )
          .padding(.top, nodeTop)
      }
      .frame(width: gutterWidth)
      .frame(maxHeight: .infinity)

      content()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct TimelineRailLine: View {
  let connectsUp: Bool
  let connectsDown: Bool
  let nodeTop: CGFloat
  let nodeSize: CGFloat
  let lineWidth: CGFloat
  let color: Color

  var body: some View {
    GeometryReader { geo in
      let midX = geo.size.width / 2
      let nodeCenterY = nodeTop + nodeSize / 2
      Path { path in
        if connectsUp {
          path.move(to: CGPoint(x: midX, y: 0))
          path.addLine(to: CGPoint(x: midX, y: max(0, nodeCenterY - nodeSize / 2)))
        }
        if connectsDown {
          path.move(to: CGPoint(x: midX, y: min(geo.size.height, nodeCenterY + nodeSize / 2)))
          path.addLine(to: CGPoint(x: midX, y: geo.size.height))
        }
      }
      .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
  }
}

extension View {
  /// Envolve a row no gutter do trilho quando `enabled`.
  @ViewBuilder
  func timelineRail(
    enabled: Bool,
    nodeColor: Color,
    connectsUp: Bool,
    connectsDown: Bool
  ) -> some View {
    if enabled {
      TimelineRailRow(
        nodeColor: nodeColor,
        connectsUp: connectsUp,
        connectsDown: connectsDown
      ) {
        self
      }
    } else {
      self
    }
  }
}

enum TimelineRailNodeColor {
  static func forTask(_ task: Task) -> Color {
    if task.done { return AppColors.textTertiary }
    if let chip = task.dueDateChipColor { return chip }
    if let due = task.dueDate { return TaskMapper.dateColor(for: due, done: task.done) }
    return AppColors.dateDueToday
  }

  static func forSubtask(_ sub: Subtask) -> Color {
    if sub.done { return AppColors.textTertiary }
    if let chip = sub.dueDateChipColor { return chip }
    if let due = sub.dueDate { return TaskMapper.dateColor(for: due, done: sub.done) }
    return AppColors.dateDueToday
  }

  static func forScheduleItem(_ item: ScheduleItem) -> Color {
    switch item {
    case .task(let task):
      forTask(task)
    case .subtask(let entry):
      forSubtask(entry.subtask)
    case .calendarEvent:
      AppColors.priorityLow
    }
  }
}
