import SwiftUI

// Paridade lib/widgets/settings/notifications_sheet.dart
struct NotificationsPreviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  @State private var items: [NotificationService.SchedulableNotificationItem] = []
  @State private var loading = true

  var body: some View {
    let c = theme.colors

    NavigationStack {
      Group {
        if loading {
          ProgressView().tint(c.accent)
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if items.isEmpty {
          EmptyStateView(icon: .notifications, title: "Nenhuma notificação agendada", subtitle: "Tarefas e subtarefas com data e hora futuras aparecem aqui")
            .stackedStandaloneEmptyState()
        } else {
          List {
            ForEach(items) { item in
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(c.accent)
                  .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(c.textPrimary)
                  if let parent = item.parentTitle {
                    Text(parent)
                      .font(.system(size: 12))
                      .foregroundStyle(c.textTertiary)
                      .lineLimit(1)
                  }
                  if let label = dueLabel(item.dueDate, time: item.time), !label.isEmpty {
                    Text(label)
                      .font(.system(size: 13))
                      .foregroundStyle(c.textSecondary)
                  }
                }
              }
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .background(c.background)
      .navigationTitle("Próximas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundStyle(c.textSecondary)
          }
        }
      }
      .task { await load() }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func dueLabel(_ date: Date?, time: String?) -> String? {
    guard let date, let time, !time.isEmpty else { return nil }
    guard TaskMapper.combinedDateTime(dueDate: date, time: time) != nil else { return nil }
    let today = Calendar.current.startOfDay(for: Date())
    let due = Calendar.current.startOfDay(for: date)
    let diff = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
    let timeLabel = TaskMapper.formatTimeDisplay(time)
    switch diff {
    case 0: return "Hoje às \(timeLabel)"
    case 1: return "Amanhã às \(timeLabel)"
    default: return "Em \(diff) dias às \(timeLabel)"
    }
  }

  private func load() async {
    loading = true
    defer { loading = false }
    items = await NotificationService.shared.fetchSchedulableItems(limit: 20)
  }
}
