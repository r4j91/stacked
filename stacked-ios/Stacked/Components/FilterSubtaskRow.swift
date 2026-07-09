import SwiftUI

struct FilterSubtaskRow: View {
  @Environment(ThemeManager.self) private var theme
  let subtask: Subtask
  let parent: Task
  let labelCatalog: [TaskLabel]
  var onToggle: () -> Void
  var onTap: () -> Void

  var body: some View {
    let c = theme.colors
    let labels = resolvedLabels
    let hasExtra = (subtask.description?.isEmpty == false) || subtask.dueDate != nil || !labels.isEmpty

    HStack(alignment: hasExtra ? .top : .center, spacing: 0) {
      Button(action: onToggle) {
        DoneCircle(
          done: subtask.done,
          size: DoneCircle.listRowCircleSize,
          borderWidth: DoneCircle.RingStyle.borderWidth,
          tickSize: 13,
          ringColor: subtask.priority?.color ?? c.textTertiary,
          ringFillAlpha: subtask.done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha
        )
        .padding(.horizontal, 4)
        .padding(.vertical, hasExtra ? 13 : 0)
      }
      .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))

      Button(action: onTap) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(subtask.title)
              .font(AppTypography.taskTitle)
              .foregroundStyle(subtask.done ? c.textTertiary : c.textPrimary)
              .strikethrough(subtask.done)
              .lineLimit(1)
              .layoutPriority(1)
            Spacer(minLength: 4)
            if let timeDisplay = subtask.timeDisplay {
              HStack(spacing: 2) {
                StackedIcons.icon(.clock, size: 11, color: c.textTertiary)
                Text(timeDisplay)
                  .font(AppTypography.timeChip)
                  .foregroundStyle(c.textTertiary)
              }
              .fixedSize()
            }
          }

          Text(parentContext)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)

          if hasExtra {
            TaskMetaLine(
              labels: labels,
              dueDate: subtask.dueDate,
              dueDateLabel: subtask.dueDateChipLabel,
              dueDateColor: subtask.dueDateChipColor,
              dateDone: subtask.done
            )
          }
        }
        .padding(.vertical, hasExtra ? 9 : 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(PressableStyle())
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 2)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(c.textTertiary.opacity(0.12), lineWidth: 1)
        .background(RoundedRectangle(cornerRadius: 10).fill(c.surface))
    )
  }

  private var parentContext: String {
    if parent.project.isEmpty { return parent.title }
    return "\(parent.title) · \(parent.project)"
  }

  private var resolvedLabels: [TaskLabel] {
    let source = !labelCatalog.isEmpty ? labelCatalog : parent.labels
    return subtask.labelIds.compactMap { id in source.first(where: { $0.id == id }) }
  }
}
