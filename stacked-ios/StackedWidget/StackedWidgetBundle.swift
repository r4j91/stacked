import AppIntents
import WidgetKit
import SwiftUI

@main
struct StackedWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
  }
}

struct TodayWidget: Widget {
  let kind = "TodayWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: StackedWidgetIntent.self, provider: TodayWidgetProvider()) { entry in
      TodayWidgetView(entry: entry)
        .containerBackground(for: .widget) {
          WidgetTheme.background
        }
    }
    .configurationDisplayName("Stacked")
    .description("Tarefas de hoje ou próximas — configure o modo ao adicionar.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct TodayWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
  let mode: WidgetDisplayMode

  var presentation: WidgetPresentation {
    WidgetPresentation(mode: mode, snapshot: snapshot)
  }
}

struct TodayWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TodayWidgetEntry {
    TodayWidgetEntry(date: Date(), snapshot: .empty, mode: .smart)
  }

  func snapshot(for configuration: StackedWidgetIntent, in context: Context) async -> TodayWidgetEntry {
    let snapshot = context.isPreview ? .preview : WidgetSnapshotStore.load()
    return TodayWidgetEntry(date: Date(), snapshot: snapshot, mode: configuration.displayMode)
  }

  func timeline(for configuration: StackedWidgetIntent, in context: Context) async -> Timeline<TodayWidgetEntry> {
    let snapshot = WidgetSnapshotStore.load()
    let entry = TodayWidgetEntry(date: Date(), snapshot: snapshot, mode: configuration.displayMode)
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    return Timeline(entries: [entry], policy: .after(next))
  }
}

struct TodayWidgetView: View {
  @Environment(\.widgetFamily) private var family

  let entry: TodayWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      TodayWidgetMediumView(presentation: entry.presentation, snapshot: entry.snapshot)
    default:
      TodayWidgetSmallView(presentation: entry.presentation, snapshot: entry.snapshot)
    }
  }
}

// MARK: - Small

private struct TodayWidgetSmallView: View {
  let presentation: WidgetPresentation
  let snapshot: WidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header

      Spacer(minLength: 4)

      content

      Spacer(minLength: 0)

      if snapshot.isAuthenticated, snapshot.updatedAt != .distantPast {
        footer
      }
    }
    .padding(14)
    .widgetURL(presentation.deepLink)
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(presentation.headerTitle)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(WidgetTheme.accent)
      Spacer(minLength: 0)
      if presentation.showsOverdueBadge {
        Text("\(snapshot.overdueCount)")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(WidgetTheme.overdue)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(WidgetTheme.overdue.opacity(0.16))
          .clipShape(Capsule())
      } else if presentation.showsTodayClearHint {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(WidgetTheme.success.opacity(0.85))
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    switch presentation.activeSource {
    case .signedOut:
      signedOutState
    case .allClear:
      clearState
    case .today, .upcoming:
      activeListState
    }
  }

  private var activeListState: some View {
    VStack(alignment: .leading, spacing: 6) {
      if presentation.showsTodayClearHint {
        Text("Hoje livre")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(WidgetTheme.success.opacity(0.9))
      }

      Text("\(presentation.primaryCount)")
        .font(.system(size: 36, weight: .heavy))
        .foregroundStyle(WidgetTheme.textPrimary)
        .tracking(-1)

      Text(presentation.countLabel)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(WidgetTheme.textSecondary)

      if !presentation.displayTasks.isEmpty {
        VStack(alignment: .leading, spacing: 5) {
          ForEach(presentation.displayTasks.prefix(2)) { task in
            taskRow(task)
          }
        }
        .padding(.top, 2)
      }
    }
  }

  private var signedOutState: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Entre no app")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(WidgetTheme.textPrimary)
      Text("Abra o Stacked para sincronizar suas tarefas.")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(WidgetTheme.textSecondary)
        .lineLimit(2)
    }
  }

  private var clearState: some View {
    VStack(alignment: .leading, spacing: 4) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(WidgetTheme.success.opacity(0.9))
      Text(presentation.mode == .upcoming ? "Nada agendado" : "Tudo em dia")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(WidgetTheme.textPrimary)
      if snapshot.completedTodayCount > 0, presentation.mode != .upcoming {
        Text("\(snapshot.completedTodayCount) concluída\(snapshot.completedTodayCount == 1 ? "" : "s") hoje")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(WidgetTheme.textSecondary)
      }
    }
  }

  private var footer: some View {
    Text(relativeUpdated)
      .font(.system(size: 9, weight: .medium))
      .foregroundStyle(WidgetTheme.textSecondary.opacity(0.75))
  }

  private var relativeUpdated: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.unitsStyle = .abbreviated
    return "Atualizado \(formatter.localizedString(for: snapshot.updatedAt, relativeTo: Date()))"
  }

  @ViewBuilder
  private func taskRow(_ task: WidgetTaskItem) -> some View {
    let row = HStack(spacing: 6) {
      Circle()
        .fill(task.isOverdue ? WidgetTheme.overdue : WidgetTheme.textSecondary.opacity(0.45))
        .frame(width: 5, height: 5)
      if let dateLabel = task.dateLabel {
        Text(dateLabel)
          .font(.system(size: 9.5, weight: .semibold))
          .foregroundStyle(WidgetTheme.textSecondary)
          .lineLimit(1)
      }
      Text(task.title)
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(WidgetTheme.textPrimary.opacity(0.9))
        .lineLimit(1)
    }

    if TaskIdentity.isValidUUID(task.id) {
      Link(destination: WidgetDeepLink.task(task.id)) { row }
    } else {
      row
    }
  }
}

// MARK: - Medium

private struct TodayWidgetMediumView: View {
  let presentation: WidgetPresentation
  let snapshot: WidgetSnapshot

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      leftColumn
        .frame(maxWidth: .infinity, alignment: .leading)

      Rectangle()
        .fill(WidgetTheme.textSecondary.opacity(0.14))
        .frame(width: 1)
        .padding(.vertical, 2)

      rightColumn
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(14)
    .widgetURL(presentation.deepLink)
  }

  private var leftColumn: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Text(presentation.headerTitle)
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(WidgetTheme.accent)
        if presentation.showsTodayClearHint {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 13))
            .foregroundStyle(WidgetTheme.success)
        }
      }

      switch presentation.activeSource {
      case .signedOut:
        Text("Entre no app para ver suas tarefas.")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(WidgetTheme.textSecondary)
          .lineLimit(3)
      case .allClear:
        VStack(alignment: .leading, spacing: 6) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 26))
            .foregroundStyle(WidgetTheme.success)
          Text(presentation.mode == .upcoming ? "Nada agendado" : "Tudo em dia")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(WidgetTheme.textPrimary)
          if snapshot.completedTodayCount > 0, presentation.mode != .upcoming {
            Text("\(snapshot.completedTodayCount) concluída\(snapshot.completedTodayCount == 1 ? "" : "s") hoje")
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(WidgetTheme.textSecondary)
          }
        }
      case .today:
        statBlock(value: presentation.primaryCount, label: presentation.countLabel, accent: WidgetTheme.textPrimary)
        if snapshot.overdueCount > 0 {
          statBlock(value: snapshot.overdueCount, label: "atrasadas", accent: WidgetTheme.overdue)
        }
        if snapshot.completedTodayCount > 0 {
          statBlock(value: snapshot.completedTodayCount, label: "concluídas", accent: WidgetTheme.success)
        }
      case .upcoming:
        statBlock(value: presentation.primaryCount, label: presentation.countLabel, accent: WidgetTheme.textPrimary)
        if presentation.showsTodayClearHint {
          Text("Hoje livre")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(WidgetTheme.success.opacity(0.9))
        }
      }

      Spacer(minLength: 0)

      if snapshot.isAuthenticated, snapshot.updatedAt != .distantPast {
        Text(relativeUpdated)
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(WidgetTheme.textSecondary.opacity(0.75))
      }
    }
  }

  private var rightColumn: some View {
    VStack(alignment: .leading, spacing: 6) {
      if !presentation.displayTasks.isEmpty {
        Text(presentation.activeSource == .upcoming ? "PRÓXIMAS" : "TAREFAS")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(WidgetTheme.textSecondary)
          .tracking(0.6)

        ForEach(presentation.displayTasks.prefix(4)) { task in
          mediumTaskRow(task)
        }
      } else if presentation.activeSource == .allClear, presentation.mode == .smart, !snapshot.upcomingTasks.isEmpty {
        // Modo hoje puro com dia livre — ainda mostra preview de em breve como dica
        EmptyView()
      } else {
        Spacer(minLength: 0)
      }
    }
  }

  private func statBlock(value: Int, label: String, accent: Color) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 5) {
      Text("\(value)")
        .font(.system(size: 22, weight: .heavy))
        .foregroundStyle(accent)
      Text(label)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(WidgetTheme.textSecondary)
    }
  }

  @ViewBuilder
  private func mediumTaskRow(_ task: WidgetTaskItem) -> some View {
    let row = HStack(spacing: 7) {
      RoundedRectangle(cornerRadius: 1.5, style: .continuous)
        .fill(task.isOverdue ? WidgetTheme.overdue : WidgetTheme.accent.opacity(0.55))
        .frame(width: 3, height: 14)
      VStack(alignment: .leading, spacing: 1) {
        if let dateLabel = task.dateLabel {
          Text(dateLabel)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(WidgetTheme.textSecondary)
            .lineLimit(1)
        }
        Text(task.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(WidgetTheme.textPrimary.opacity(0.92))
          .lineLimit(1)
      }
    }
    .padding(.vertical, 1)

    if TaskIdentity.isValidUUID(task.id) {
      Link(destination: WidgetDeepLink.task(task.id)) { row }
    } else {
      row
    }
  }

  private var relativeUpdated: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.unitsStyle = .abbreviated
    return "Atualizado \(formatter.localizedString(for: snapshot.updatedAt, relativeTo: Date()))"
  }
}

#if DEBUG
#Preview(as: .systemSmall) {
  TodayWidget()
} timeline: {
  TodayWidgetEntry(date: .now, snapshot: .preview, mode: .smart)
  TodayWidgetEntry(date: .now, snapshot: .previewToday, mode: .today)
}

#Preview(as: .systemMedium) {
  TodayWidget()
} timeline: {
  TodayWidgetEntry(date: .now, snapshot: .preview, mode: .smart)
  TodayWidgetEntry(date: .now, snapshot: .previewToday, mode: .today)
}
#endif
