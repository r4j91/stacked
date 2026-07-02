import SwiftUI

// Paridade lib/widgets/task_tile.dart TaskMetaLine + TagChip
struct TaskMetaLine: View {
  @Environment(ThemeManager.self) private var theme

  let labels: [TaskLabel]
  var dueDate: Date?
  /// FASE5: quando presentes, evitam formatação no body.
  var dueDateLabel: String? = nil
  var dueDateColor: Color? = nil
  var subtasksDone: Int = 0
  var subtasksTotal: Int = 0
  var commentCount: Int = 0
  var projectName: String?
  var maxLabels: Int = 3

  var body: some View {
    let items = metaItems
    if items.isEmpty {
      EmptyView()
    } else {
      FlowLayout(spacing: 6, lineSpacing: 4) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          item
        }
      }
      .padding(.top, 4)
    }
  }

  private var metaItems: [AnyView] {
    var result: [AnyView] = []
    let c = theme.colors

    if let projectName, !projectName.isEmpty, projectName != "Sem projeto" {
      result.append(AnyView(
        Text(projectName)
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
      ))
    }

    for label in labels.prefix(maxLabels) {
      result.append(AnyView(TagChip(label: label.name, color: label.color)))
    }
    if labels.count > maxLabels {
      result.append(AnyView(TagChip(label: "+\(labels.count - maxLabels)", color: c.textTertiary, showIcon: false)))
    }

    if let dueDate {
      result.append(AnyView(dueDateChip(dueDate)))
    }

    if subtasksTotal > 0 {
      result.append(AnyView(metaCounter(icon: .logbook, value: "\(subtasksDone)/\(subtasksTotal)")))
    }

    if commentCount > 0 {
      result.append(AnyView(metaCounter(icon: .comment, value: "\(commentCount)")))
    }

    return result
  }

  private func dueDateChip(_ date: Date) -> some View {
    let color = dueDateColor ?? TaskMapper.dateColor(for: date)
    let label = dueDateLabel ?? TaskMapper.dueDateChipLabel(for: date)
    return TagChip(label: label, color: color, icon: .calendar)
  }

  // SUBSTITUIDO_FASE5: formatação inline no body a cada render
  // private func dueDateChipLabel(_ date: Date) -> String {
  //   let today = Calendar.current.startOfDay(for: Date())
  //   let due = Calendar.current.startOfDay(for: date)
  //   if due == today { return "Hoje" }
  //   let monthLabels = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
  //   let day = Calendar.current.component(.day, from: date)
  //   let month = Calendar.current.component(.month, from: date)
  //   return "\(day) \(monthLabels[month - 1])"
  // }

  private func metaCounter(icon: StackedIconKey, value: String) -> some View {
    HStack(alignment: .center, spacing: 3) {
      StackedIcons.icon(icon, size: 12, color: theme.colors.textTertiary)
      Text(value)
        .font(AppTypography.meta)
        .foregroundStyle(theme.colors.textTertiary)
    }
  }
}

struct TagChip: View {
  let label: String
  let color: Color
  var showIcon: Bool = true
  var icon: StackedIconKey = .tag

  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      if showIcon {
        StackedIcons.icon(icon, size: 11, color: color)
      }
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(color)
        .lineLimit(1)
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .background(color.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 0.8))
  }
}

// Layout simples para chips em linha com quebra — paridade Wrap crossAxisAlignment: center
struct FlowLayout: Layout {
  var spacing: CGFloat = 6
  var lineSpacing: CGFloat = 4

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x + size.width > maxWidth, x > 0 {
        x = 0
        y += rowHeight + lineSpacing
        rowHeight = 0
      }
      rowHeight = max(rowHeight, size.height)
      x += size.width + spacing
    }
    return CGSize(width: maxWidth, height: y + rowHeight)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var x = bounds.minX
    var y = bounds.minY
    var rowHeight: CGFloat = 0
    var rowStart = 0

    func placeRow(from start: Int, to end: Int, rowY: CGFloat, height: CGFloat) {
      var cursor = bounds.minX
      for index in start..<end {
        let subview = subviews[index]
        let size = subview.sizeThatFits(.unspecified)
        let yOffset = rowY + (height - size.height) / 2
        subview.place(at: CGPoint(x: cursor, y: yOffset), proposal: .unspecified)
        cursor += size.width + spacing
      }
    }

    for (index, subview) in subviews.enumerated() {
      let size = subview.sizeThatFits(.unspecified)
      if x + size.width > bounds.maxX, x > bounds.minX {
        placeRow(from: rowStart, to: index, rowY: y, height: rowHeight)
        x = bounds.minX
        y += rowHeight + lineSpacing
        rowHeight = 0
        rowStart = index
      }
      rowHeight = max(rowHeight, size.height)
      x += size.width + spacing
    }

    if rowStart < subviews.count {
      placeRow(from: rowStart, to: subviews.count, rowY: y, height: rowHeight)
    }
  }
}
