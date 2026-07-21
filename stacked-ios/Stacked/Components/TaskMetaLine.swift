import SwiftUI

// Paridade lib/widgets/task_tile.dart TaskMetaLine + TagChip
struct TaskMetaLine: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(LabelChipStyleStorage.key) private var labelChipStyleRaw = LabelChipStyleStorage.defaultRawValue
  @AppStorage(DueDateChipStyleStorage.key) private var dueDateChipStyleRaw = DueDateChipStyleStorage.defaultRawValue
  @AppStorage(TaskRowLayoutStorage.key) private var taskRowLayoutRaw = TaskRowLayoutStorage.defaultRawValue

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
  var timeDisplay: String? = nil
  /// Em breve / agrupado por dia — omitir data (hora ainda pode aparecer).
  var hideDate: Bool = false
  var maxLabels: Int = 2
  /// Anel de progresso ativo — omite o contador 0/N da meta (evita duplicar).
  var hideSubtasksCounter: Bool = false

  private var labelChipStyle: LabelChipStyle {
    LabelChipStyleStorage.style(from: labelChipStyleRaw)
  }

  private var dueDateChipStyle: DueDateChipStyle {
    DueDateChipStyleStorage.style(from: dueDateChipStyleRaw)
  }

  private var layout: TaskRowLayout {
    TaskRowLayoutStorage.layout(from: taskRowLayoutRaw)
  }

  private var showsProject: Bool {
    guard let projectName, !projectName.isEmpty else { return false }
    return projectName != "Sem projeto"
  }

  private var fusedScheduleLabel: String? {
    if hideDate {
      return timeDisplay
    }
    guard let dueDateLabel, !dueDateLabel.isEmpty else {
      return timeDisplay
    }
    if let timeDisplay, !timeDisplay.isEmpty {
      return "\(dueDateLabel) · \(timeDisplay)"
    }
    return dueDateLabel
  }

  private var hasMeta: Bool {
    switch layout {
    case .f2:
      return !labels.isEmpty
        || fusedScheduleLabel != nil
        || (!hideSubtasksCounter && subtasksTotal > 0)
        || commentCount > 0
    case .x2:
      return priority != nil
        || !labels.isEmpty
        || fusedScheduleLabel != nil
        || (!hideSubtasksCounter && subtasksTotal > 0)
        || commentCount > 0
    case .trailingTime:
      return !labels.isEmpty
        || dueDate != nil
        || (!hideSubtasksCounter && subtasksTotal > 0)
        || commentCount > 0
    case .dense:
      return showsProject
        || !labels.isEmpty
        || dueDate != nil
        || timeDisplay != nil
        || (!hideSubtasksCounter && subtasksTotal > 0)
        || commentCount > 0
    case .default:
      return showsProject
        || !labels.isEmpty
        || dueDate != nil
        || (!hideSubtasksCounter && subtasksTotal > 0)
        || commentCount > 0
    }
  }

  private var visibleLabels: [TaskLabel] {
    Array(labels.prefix(maxLabels))
  }

  private var overflowLabelCount: Int {
    max(0, labels.count - visibleLabels.count)
  }

  private var resolvedSubtasksLabel: String? {
    if hideSubtasksCounter { return nil }
    if let subtasksCounterLabel, !subtasksCounterLabel.isEmpty { return subtasksCounterLabel }
    guard subtasksTotal > 0 else { return nil }
    return "\(subtasksDone)/\(subtasksTotal)"
  }

  var body: some View {
    if hasMeta {
      let c = theme.colors
      Group {
        if layout.isDense {
          denseMetaLine(colors: c)
        } else {
          chipMetaLine(colors: c)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .clipped()
      .padding(.top, layout.isDense ? 2 : 4)
    }
  }

  @ViewBuilder
  private func denseMetaLine(colors: AppThemeColors) -> some View {
    let parts = denseMetaParts
    if !parts.isEmpty {
      Text(parts.joined(separator: " · "))
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(colors.textSecondary)
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }

  private var denseMetaParts: [String] {
    var parts: [String] = []
    if !hideDate, let dueDateLabel, !dueDateLabel.isEmpty {
      if let timeDisplay, !timeDisplay.isEmpty {
        parts.append("\(dueDateLabel) \(timeDisplay)")
      } else {
        parts.append(dueDateLabel)
      }
    } else if let timeDisplay, !timeDisplay.isEmpty {
      parts.append(timeDisplay)
    }
    if showsProject, let projectName {
      parts.append(projectName)
    }
    for label in visibleLabels {
      parts.append(label.name)
    }
    if overflowLabelCount > 0 {
      parts.append("+\(overflowLabelCount)")
    }
    if let counter = resolvedSubtasksLabel {
      parts.append(counter)
    }
    if commentCount > 0 {
      parts.append("\(commentCount)")
    }
    return parts
  }

  @ViewBuilder
  private func chipMetaLine(colors: AppThemeColors) -> some View {
    HStack(spacing: 6) {
      if layout == .default {
        if showsProject, let projectName {
          ProjectChip(name: projectName)
            .layoutPriority(-1)
        }

        if dueDate != nil {
          dueDateChip
        }

        if let counter = resolvedSubtasksLabel {
          metaCounter(icon: .logbook, value: counter)
        }

        if commentCount > 0 {
          metaCounter(icon: .comment, value: "\(commentCount)")
        }

        ForEach(visibleLabels) { label in
          TagChip(label: label.name, color: label.color, style: labelChipStyle)
            .layoutPriority(-1)
        }

        if overflowLabelCount > 0 {
          TagChip(
            label: "+\(overflowLabelCount)",
            color: colors.textTertiary,
            showIcon: false,
            style: labelChipStyle
          )
        }
      } else if layout == .trailingTime {
        if dueDate != nil {
          // Só a data — hora vai na coluna trailing.
          dueDateChipOnlyDate
        }

        if let counter = resolvedSubtasksLabel {
          metaCounter(icon: .logbook, value: counter)
        }

        if commentCount > 0 {
          metaCounter(icon: .comment, value: "\(commentCount)")
        }

        ForEach(visibleLabels) { label in
          TagChip(label: label.name, color: label.color, style: labelChipStyle)
            .layoutPriority(-1)
        }

        if overflowLabelCount > 0 {
          TagChip(
            label: "+\(overflowLabelCount)",
            color: colors.textTertiary,
            showIcon: false,
            style: labelChipStyle
          )
        }
      } else {
        if layout == .x2, let priority {
          PriorityFlagChip(priority: priority)
        }

        if let fused = fusedScheduleLabel {
          FusedScheduleFlat(
            label: fused,
            color: dueDateColor ?? colors.textSecondary
          )
        }

        ForEach(visibleLabels) { label in
          TagChip(label: label.name, color: label.color, style: labelChipStyle)
            .layoutPriority(-1)
        }

        if overflowLabelCount > 0 {
          TagChip(
            label: "+\(overflowLabelCount)",
            color: colors.textTertiary,
            showIcon: false,
            style: labelChipStyle
          )
        }

        if let counter = resolvedSubtasksLabel {
          metaCounter(icon: .logbook, value: counter)
        }

        if commentCount > 0 {
          metaCounter(icon: .comment, value: "\(commentCount)")
        }
      }
    }
  }

  /// Chip de data sem fundir hora (layout C).
  @ViewBuilder
  private var dueDateChipOnlyDate: some View {
    if let label = dueDateLabel, let color = dueDateColor {
      DueDateChip(
        label: label,
        color: color,
        day: dueDate.map { Calendar.current.component(.day, from: $0) },
        style: dueDateChipStyle
      )
    }
  }

  @ViewBuilder
  private var dueDateChip: some View {
    if let label = dueDateLabel, let color = dueDateColor {
      DueDateChip(
        label: label,
        color: color,
        day: dueDate.map { Calendar.current.component(.day, from: $0) },
        style: dueDateChipStyle
      )
    } else {
      DueDateChip(
        label: "···",
        color: theme.colors.textTertiary,
        day: nil,
        style: dueDateChipStyle
      )
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

/// Eyebrow F2/X2 — projeto · P1 acima do título.
struct TaskRowEyebrow: View {
  @Environment(ThemeManager.self) private var theme
  let projectName: String?
  let priority: Priority?
  let layout: TaskRowLayout

  private var hasProject: Bool {
    guard let projectName, !projectName.isEmpty else { return false }
    return projectName != "Sem projeto"
  }

  private var showPriority: Bool {
    layout == .f2 && priority != nil
  }

  var body: some View {
    if hasProject || showPriority {
      HStack(spacing: 6) {
        if hasProject, let projectName {
          Text(projectName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.colors.textTertiary)
            .lineLimit(1)
        }
        if hasProject && showPriority {
          Circle()
            .fill(theme.colors.textTertiary.opacity(0.6))
            .frame(width: 3, height: 3)
        }
        if showPriority, let priority {
          Text(priority.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(priority.color)
            .tracking(0.4)
        }
      }
      .padding(.bottom, 2)
    }
  }
}

/// Agenda fundida plana (Hoje · 14:30) — layouts F2/X2.
private struct FusedScheduleFlat: View {
  let label: String
  let color: Color

  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      StackedIcons.icon(.calendar, size: 14, color: color)
      Text(label)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(color)
        .lineLimit(1)
        .monospacedDigit()
    }
  }
}

private struct PriorityFlagChip: View {
  let priority: Priority

  var body: some View {
    Text(priority.label)
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(priority.color)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(priority.color.opacity(0.14))
      .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
  }
}

/// Contexto de projeto — mesmo visual Plano das etiquetas (ícone + texto, sem container).
struct ProjectChip: View {
  @Environment(ThemeManager.self) private var theme
  let name: String

  var body: some View {
    let c = theme.colors
    HStack(alignment: .center, spacing: 4) {
      StackedIcons.icon(.folder, size: 14, color: c.textSecondary)
      Text(name)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .lineLimit(1)
    }
  }
}

struct TagChip: View {
  @Environment(ThemeManager.self) private var theme

  let label: String
  let color: Color
  var showIcon: Bool = true
  var icon: StackedIconKey = .tag
  /// `.soft` fixo para prioridade; etiquetas passam a preferência do Aparência.
  var style: LabelChipStyle = .soft

  var body: some View {
    switch style {
    case .soft:
      softChip
    case .flat:
      flatChip
    case .dot:
      dotChip
    case .ink:
      inkChip
    case .outline:
      outlineChip
    }
  }

  private var softChip: some View {
    chipContent(textColor: color, iconColor: color)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(color.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 0.8))
  }

  private var flatChip: some View {
    chipContent(textColor: color, iconColor: color)
  }

  private var dotChip: some View {
    HStack(alignment: .center, spacing: 5) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(theme.colors.textSecondary)
        .lineLimit(1)
    }
  }

  private var inkChip: some View {
    chipContent(textColor: theme.colors.textSecondary, iconColor: color)
  }

  private var outlineChip: some View {
    chipContent(textColor: color, iconColor: color)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.50), lineWidth: 0.8))
  }

  @ViewBuilder
  private func chipContent(textColor: Color, iconColor: Color) -> some View {
    HStack(alignment: .center, spacing: 4) {
      if showIcon {
        StackedIcons.icon(icon, size: 14, color: iconColor)
      }
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(textColor)
        .lineLimit(1)
    }
  }
}

/// Mini preview do layout de card no menu Aparência.
struct TaskRowLayoutPreview: View {
  let layout: TaskRowLayout
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(colors.surface)
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(
          selected ? colors.accent.opacity(0.55) : colors.textTertiary.opacity(0.35),
          lineWidth: selected ? 1.2 : 0.8
        )
      VStack(alignment: .leading, spacing: 3) {
        switch layout {
        case .default:
          Capsule().fill(colors.textPrimary.opacity(0.7)).frame(width: 44, height: 3)
          HStack(spacing: 3) {
            Capsule().fill(colors.textSecondary.opacity(0.55)).frame(width: 14, height: 2)
            Capsule().fill(Color(hex: 0xB18CF5).opacity(0.55)).frame(width: 12, height: 4)
            Capsule().fill(colors.accent.opacity(0.45)).frame(width: 12, height: 4)
          }
        case .f2:
          HStack(spacing: 2) {
            Capsule().fill(colors.textTertiary).frame(width: 16, height: 2)
            Circle().fill(AppColors.priorityHigh).frame(width: 3, height: 3)
          }
          Capsule().fill(colors.textPrimary.opacity(0.7)).frame(width: 44, height: 3)
          Capsule().fill(colors.accent.opacity(0.7)).frame(width: 28, height: 2)
        case .x2:
          Capsule().fill(colors.textTertiary).frame(width: 16, height: 2)
          Capsule().fill(colors.textPrimary.opacity(0.7)).frame(width: 44, height: 3)
          HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
              .fill(AppColors.priorityHigh.opacity(0.4))
              .frame(width: 10, height: 6)
            Capsule().fill(colors.accent.opacity(0.7)).frame(width: 22, height: 2)
          }
        case .trailingTime:
          HStack(alignment: .top, spacing: 4) {
            VStack(alignment: .leading, spacing: 3) {
              Capsule().fill(colors.textPrimary.opacity(0.7)).frame(width: 36, height: 3)
              Capsule().fill(colors.accent.opacity(0.55)).frame(width: 18, height: 2)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
              Capsule().fill(colors.textSecondary.opacity(0.75)).frame(width: 16, height: 3)
              Capsule().fill(colors.textTertiary.opacity(0.55)).frame(width: 12, height: 2)
            }
          }
        case .dense:
          Capsule().fill(colors.textPrimary.opacity(0.65)).frame(width: 48, height: 2.5)
          Capsule().fill(colors.textTertiary.opacity(0.55)).frame(width: 40, height: 2)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(.horizontal, 10)
    }
    .frame(width: 72, height: 36)
  }
}

/// Mini preview do estilo de etiqueta no menu Aparência.
struct LabelChipStylePreview: View {
  let style: LabelChipStyle
  let colors: AppThemeColors
  var selected: Bool = false

  private let sample = Color(hex: 0xB18CF5)

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(colors.surface)
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(
          selected ? colors.accent.opacity(0.55) : colors.textTertiary.opacity(0.35),
          lineWidth: selected ? 1.2 : 0.8
        )
      TagChip(label: "Ideia", color: sample, style: style)
        .scaleEffect(0.92)
    }
    .frame(width: 72, height: 36)
  }
}

/// Data na meta line — estilos do Aparência (independente das etiquetas).
struct DueDateChip: View {
  @Environment(ThemeManager.self) private var theme

  let label: String
  let color: Color
  var day: Int? = nil
  var style: DueDateChipStyle = .soft

  var body: some View {
    switch style {
    case .soft:
      softChip
    case .flat:
      flatChip
    case .plain:
      plainChip
    case .day:
      dayChip
    case .outline:
      outlineChip
    }
  }

  private var softChip: some View {
    chipContent(textColor: color, showIcon: true)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(color.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 0.8))
  }

  private var flatChip: some View {
    chipContent(textColor: color, showIcon: true)
  }

  private var plainChip: some View {
    Text(label)
      .font(.system(size: 12, weight: .medium))
      .foregroundStyle(color)
      .lineLimit(1)
  }

  private var dayChip: some View {
    HStack(alignment: .center, spacing: 5) {
      dayBadge
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(color)
        .lineLimit(1)
    }
  }

  private var outlineChip: some View {
    chipContent(textColor: color, showIcon: true)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.50), lineWidth: 0.8))
  }

  private var dayBadge: some View {
    Text(day.map(String.init) ?? "–")
      .font(.system(size: 9, weight: .bold, design: .rounded))
      .foregroundStyle(color)
      .frame(width: 16, height: 14)
      .background(color.opacity(0.14))
      .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 3, style: .continuous)
          .stroke(color.opacity(0.40), lineWidth: 0.7)
      )
  }

  private func chipContent(textColor: Color, showIcon: Bool) -> some View {
    HStack(alignment: .center, spacing: 4) {
      if showIcon {
        StackedIcons.icon(.calendar, size: 14, color: color)
      }
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(textColor)
        .lineLimit(1)
    }
  }
}

/// Mini preview do estilo de data no menu Aparência.
struct DueDateChipStylePreview: View {
  let style: DueDateChipStyle
  let colors: AppThemeColors
  var selected: Bool = false

  private let sample = Color(hex: 0x5FD3DC)

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(colors.surface)
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(
          selected ? colors.accent.opacity(0.55) : colors.textTertiary.opacity(0.35),
          lineWidth: selected ? 1.2 : 0.8
        )
      DueDateChip(label: "Hoje", color: sample, day: 17, style: style)
        .scaleEffect(0.92)
    }
    .frame(width: 72, height: 36)
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
