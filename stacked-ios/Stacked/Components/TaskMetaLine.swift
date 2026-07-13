import SwiftUI

// Paridade lib/widgets/task_tile.dart TaskMetaLine + TagChip
struct TaskMetaLine: View {
  @Environment(ThemeManager.self) private var theme

  let labels: [TaskLabel]
  var dueDate: Date?
  var priority: Priority?
  /// FASE5 / PERF_FASEB2_ETAPA2: memos obrigatórios — sem formatação no body.
  var dueDateLabel: String? = nil
  var dueDateColor: Color? = nil
  var dateDone: Bool = false // reservado — cor vem do memo dueDateColor
  var subtasksDone: Int = 0
  var subtasksTotal: Int = 0
  /// PERF_FASEB2_ETAPA4: "2/5" pré-computado; se nil, monta a partir dos ints (sem DateFormatter).
  var subtasksCounterLabel: String? = nil
  var commentCount: Int = 0
  var projectName: String?
  var maxLabels: Int = 2

  private var showsProject: Bool {
    guard let projectName, !projectName.isEmpty else { return false }
    return projectName != "Sem projeto"
  }

  private var hasMeta: Bool {
    showsProject
      || !labels.isEmpty
      || priority != nil
      || dueDate != nil
      || subtasksTotal > 0
      || commentCount > 0
  }

  private var visibleLabels: [TaskLabel] {
    Array(labels.prefix(maxLabels))
  }

  private var overflowLabelCount: Int {
    max(0, labels.count - visibleLabels.count)
  }

  private var resolvedSubtasksLabel: String? {
    if let subtasksCounterLabel, !subtasksCounterLabel.isEmpty { return subtasksCounterLabel }
    guard subtasksTotal > 0 else { return nil }
    return "\(subtasksDone)/\(subtasksTotal)"
  }

  var body: some View {
    if hasMeta {
      let c = theme.colors
      // PERF_FASEB2_ETAPA3: uma linha — FlowLayout multi-linha removido do path quente.
      // PERF_FASEB2_ETAPA3 (legado FlowLayout):
      // FlowLayout(spacing: 6, lineSpacing: 4) {
      //   if showsProject, let projectName { Text(projectName)... }
      //   ForEach(Array(labels.prefix(maxLabels))) { ... }
      //   if labels.count > maxLabels { TagChip("+N") }
      //   if let priority { TagChip(...) }
      //   if let dueDate { dueDateChip(dueDate) }
      //   if subtasksTotal > 0 { metaCounter(...) }
      //   if commentCount > 0 { metaCounter(...) }
      // }
      // .padding(.top, 4)
      HStack(spacing: 6) {
        // Prioridade de exibição: data → subtarefas → resto; labels colapsam primeiro via +N.
        if dueDate != nil {
          dueDateChip
        }

        if let counter = resolvedSubtasksLabel {
          metaCounter(icon: .logbook, value: counter)
        }

        if commentCount > 0 {
          metaCounter(icon: .comment, value: "\(commentCount)")
        }

        if let priority {
          TagChip(label: priority.label, color: priority.color, showIcon: true, icon: .flag)
        }

        if showsProject, let projectName {
          Text(projectName)
            .font(AppTypography.metaSmall)
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)
            .layoutPriority(-1)
        }

        ForEach(visibleLabels) { label in
          TagChip(label: label.name, color: label.color)
            .layoutPriority(-1)
        }

        if overflowLabelCount > 0 {
          TagChip(label: "+\(overflowLabelCount)", color: c.textTertiary, showIcon: false)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .clipped()
      .padding(.top, 4)
    }
  }

  @ViewBuilder
  private var dueDateChip: some View {
    // PERF_FASEB2_ETAPA2: sem fallback TaskMapper no body.
    // let color = dueDateColor ?? TaskMapper.dateColor(for: date, done: dateDone)
    // let label = dueDateLabel ?? TaskMapper.dueDateChipLabel(for: date)
    if let label = dueDateLabel, let color = dueDateColor {
      TagChip(label: label, color: color, icon: .calendar)
    } else {
      // Placeholder de largura estável se memo ausente (não deve ocorrer após Etapa 2).
      TagChip(label: "···", color: theme.colors.textTertiary, icon: .calendar)
        .opacity(0.45)
        .accessibilityHidden(true)
    }
  }

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

// PERF_FASEB2_ETAPA3: FlowLayout multi-linha — path quente substituído por HStack 1 linha.
// Mantido comentado para rollback; não usado nas listas de tarefa.
/*
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
*/
