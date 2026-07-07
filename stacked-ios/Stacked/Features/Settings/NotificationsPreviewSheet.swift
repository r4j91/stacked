import SwiftUI

// Paridade lib/widgets/settings/notifications_sheet.dart
struct NotificationsPreviewSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  @State private var tasks: [Task] = []
  @State private var loading = true

  var body: some View {
    let c = theme.colors

    NavigationStack {
      Group {
        if loading {
          ProgressView().tint(c.accent)
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if tasks.isEmpty {
          EmptyStateView(icon: .notifications, title: "Nenhuma notificação agendada", subtitle: "Tarefas com data futura aparecem aqui")
            .stackedStandaloneEmptyState()
        } else {
          List {
            ForEach(tasks) { task in
              HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(c.accent)
                VStack(alignment: .leading, spacing: 2) {
                  Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(c.textPrimary)
                  if let label = dueLabel(task.dueDate), !label.isEmpty {
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

  private func dueLabel(_ date: Date?) -> String? {
    guard let date else { return nil }
    let today = Calendar.current.startOfDay(for: Date())
    let due = Calendar.current.startOfDay(for: date)
    let diff = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
    switch diff {
    case 0: return "Hoje"
    case 1: return "Amanhã"
    default: return "Em \(diff) dias"
    }
  }

  private func load() async {
    loading = true
    defer { loading = false }
    let all = (try? await TaskRepository.shared.fetchDatedPendingTasks()) ?? []
    tasks = Array(all.prefix(20))
  }
}
