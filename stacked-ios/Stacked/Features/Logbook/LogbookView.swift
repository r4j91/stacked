import SwiftUI

// Paridade lib/screens/logbook_screen.dart
struct LogbookView: View {
  @Environment(ThemeManager.self) private var theme

  @State private var tasks: [Task] = []
  @State private var loading = true
  @State private var detailRoute: TaskDetailRoute?

  private static let months = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
  ]

  var body: some View {
    let c = theme.colors
    let grouped = groupedTasks
    let keys = grouped.keys

    NavigationStack {
      Group {
        if loading {
          ProgressView().tint(c.accent)
        } else if tasks.isEmpty {
          EmptyStateView(icon: .logbook, title: "Nenhuma tarefa concluída", subtitle: "As tarefas concluídas aparecerão aqui")
        } else {
          List {
            ForEach(keys, id: \.self) { key in
              Section {
                ForEach(grouped.groups[key] ?? []) { task in
                  TaskRow(task: task, onToggle: {})
                    .opacity(0.85)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                      detailRoute = TaskDetailRoute(taskId: task.id)
                    }
                }
              } header: {
                SectionLabel(text: key)
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(c.background)
      .navigationTitle("Registro")
      .navigationBarTitleDisplayMode(.large)
      .refreshable { await load() }
      .task { await load() }
      .fullScreenCover(item: $detailRoute) { route in
        TaskDetailView(taskId: route.taskId) {
          _Concurrency.Task { await load() }
        }
        .environment(ThemeManager.shared)
      }
    }
  }

  private var groupedTasks: (keys: [String], groups: [String: [Task]]) {
    let now = Date()
    let today = Calendar.current.startOfDay(for: now)
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    var groups: [String: [Task]] = [:]
    var keys: [String] = []

    for task in tasks {
      let label: String
      if let due = task.dueDate {
        let day = Calendar.current.startOfDay(for: due)
        if day == today {
          label = "Hoje"
        } else if day == yesterday {
          label = "Ontem"
        } else {
          let month = Self.months[Calendar.current.component(.month, from: due) - 1]
          var text = "\(Calendar.current.component(.day, from: due)) de \(month)"
          if Calendar.current.component(.year, from: due) != Calendar.current.component(.year, from: now) {
            text += " de \(Calendar.current.component(.year, from: due))"
          }
          label = text
        }
      } else {
        label = "Sem data"
      }

      if groups[label] == nil { keys.append(label) }
      groups[label, default: []].append(task)
    }

    return (keys, groups)
  }

  private func load() async {
    loading = tasks.isEmpty
    defer { loading = false }
    tasks = (try? await TaskRepository.shared.fetchLogbookTasks()) ?? []
  }
}
