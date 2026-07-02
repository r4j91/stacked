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
    StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
      TodayWidgetView(entry: entry)
        .containerBackground(for: .widget) {
          Color(red: 0.10, green: 0.11, blue: 0.12)
        }
    }
    .configurationDisplayName("Hoje")
    .description("Tarefas de hoje e atrasadas.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct TodayWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct TodayWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayWidgetEntry {
    TodayWidgetEntry(date: Date(), snapshot: .empty)
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
    completion(TodayWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
    let snapshot = WidgetSnapshotStore.load()
    let entry = TodayWidgetEntry(date: Date(), snapshot: snapshot)
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

struct TodayWidgetView: View {
  let entry: TodayWidgetEntry

  var body: some View {
    let snap = entry.snapshot
    let total = snap.todayCount + snap.overdueCount

    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Hoje")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(Color(red: 0.37, green: 0.83, blue: 0.86))
        Spacer()
        if snap.overdueCount > 0 {
          Text("\(snap.overdueCount) atrasada\(snap.overdueCount == 1 ? "" : "s")")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(red: 0.94, green: 0.35, blue: 0.37))
        }
      }

      if total == 0 {
        Spacer(minLength: 0)
        Text("Tudo em dia")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.white.opacity(0.55))
        Spacer(minLength: 0)
      } else {
        Text("\(total)")
          .font(.system(size: 34, weight: .heavy))
          .foregroundStyle(.white)

        if !snap.tasks.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(snap.tasks.prefix(3)) { task in
              HStack(spacing: 6) {
                Circle()
                  .fill(task.isOverdue ? Color(red: 0.94, green: 0.35, blue: 0.37) : Color.white.opacity(0.35))
                  .frame(width: 5, height: 5)
                Text(task.title)
                  .font(.system(size: 12, weight: .medium))
                  .foregroundStyle(.white.opacity(0.88))
                  .lineLimit(1)
              }
            }
          }
        } else if let next = snap.nextTaskTitle {
          Text(next)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .lineLimit(2)
        }
      }
    }
    .padding(14)
    .widgetURL(URL(string: "stacked://today"))
  }
}
