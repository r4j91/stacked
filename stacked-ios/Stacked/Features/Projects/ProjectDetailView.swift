import SwiftUI
import Hugeicons

// Paridade lib/screens/project_detail_screen.dart
struct ProjectDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  @AppStorage("display_mode") private var displayMode = "cards"
  @AppStorage("show_completed_tasks") private var showCompleted = false
  @State private var store: ProjectDetailStore
  @State private var completedExpanded = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var showQuickAdd = false
  @State private var toolbarAnchor: CGRect = .zero
  @State private var showProjectOptions = false
  @State private var showNewSection = false
  @State private var newSectionName = ""

  let projectColorHex: String?

  init(projectId: String, projectName: String, projectColorHex: String? = nil) {
    _store = State(initialValue: ProjectDetailStore(projectId: projectId, projectName: projectName))
    self.projectColorHex = projectColorHex
  }

  private var isListMode: Bool { displayMode == "list" }

  var body: some View {
    let c = theme.colors

    List {
      if store.isLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.error {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.load() }
          }
          .listRowBackground(Color.clear)
        }
      } else {
        ForEach(store.sections) { section in
          let tasks = store.tasks(in: section.id)
          if !tasks.isEmpty {
            Section {
              ForEach(tasks) { task in
                projectTaskRow(task)
              }
            } header: {
              Text(section.name.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(c.textTertiary)
            }
          }
        }

        let uncategorized = store.tasks(in: nil)
        if !uncategorized.isEmpty {
          Section {
            ForEach(uncategorized) { task in
              projectTaskRow(task)
            }
          } header: {
            if !store.sections.isEmpty {
              Text("SEM SEÇÃO")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(c.textTertiary)
            }
          }
        }

        if store.pending.isEmpty && store.completed.isEmpty {
          Section {
            EmptyStateView(icon: .checkCircle, title: "Projeto em dia", subtitle: "Nenhuma tarefa pendente")
            .listRowBackground(Color.clear)
          }
        }

        if showCompleted && !store.completed.isEmpty {
          Section {
            Button {
              withAnimation { completedExpanded.toggle() }
            } label: {
              HStack {
                Text("Concluídas (\(store.completed.count))")
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundStyle(c.textSecondary)
                Spacer()
                StackedIcons.image(completedExpanded ? .chevronDown : .chevronRight)
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(c.textTertiary)
              }
            }
            .listRowBackground(Color.clear)

            if completedExpanded {
              ForEach(store.completed) { task in
                TaskRow(
                  task: task,
                  style: isListMode ? .list : .card,
                  onToggle: {},
                  onTap: { detailRoute = TaskDetailRoute(taskId: task.id) }
                )
                .opacity(0.7)
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
              }
            }
          }
        }
      }

      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .stackedListTailInset()
    .scrollContentBackground(.hidden)
    .background(c.background)
    .navigationTitle(store.projectName)
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackButtonHidden(false)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 6) {
          if isListMode {
            Button { openToolbarMenu() } label: {
              LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
                HStack(spacing: 5) {
                  StackedIcons.image(.list)
                    .font(.system(size: 16))
                    .foregroundStyle(c.accent)
                  Text("Lista")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(c.accent)
                }
              }
            }
            .buttonStyle(.plain)
          }

          Button { openToolbarMenu() } label: {
            LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
              StackedIcons.image(.more)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(c.textPrimary)
            }
          }
          .buttonStyle(.plain)
        }
        .readAnchor($toolbarAnchor)
      }
    }
    .refreshable { await store.load() }
    .task { await store.load() }
    .overlay {
      if showQuickAdd {
        QuickAddTaskView(
          initialProjectId: store.projectId,
          onSaved: { _Concurrency.Task { await store.load() } },
          onDismiss: { showQuickAdd = false }
        )
        .environment(ThemeManager.shared)
        .transition(.opacity)
        .zIndex(200)
      }
    }
    .animation(.easeOut(duration: 0.22), value: showQuickAdd)
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask) {
        _Concurrency.Task { await store.load() }
      }
      .environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showProjectOptions) {
      ProjectOptionsSheet(
        project: Project(
          id: store.projectId,
          name: store.projectName,
          color: AppColors.parseHex(projectColorHex, fallback: Color(hex: 0x5FD3DC))
        ),
        onEdited: { _Concurrency.Task { await store.load() } },
        onDeleted: { dismiss() }
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
    .alert("Nova seção", isPresented: $showNewSection) {
      TextField("Nome da seção", text: $newSectionName)
      Button("Criar") {
        let name = newSectionName
        newSectionName = ""
        _Concurrency.Task { await store.createSection(name: name) }
      }
      Button("Cancelar", role: .cancel) { newSectionName = "" }
    }
    .fullScreenCover(item: $detailRoute) { route in
      TaskDetailView(taskId: route.taskId) {
        _Concurrency.Task { await store.load() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private func openToolbarMenu() {
    presentAnchoredPopover(
      anchorRect: toolbarAnchor,
      items: toolbarMenuItems
    ) { value in
      handleToolbarAction(value)
    }
  }

  private var toolbarMenuItems: [PopoverMenuItem] {
    [
      PopoverMenuItem(
        id: "toggle_completed",
        icon: showCompleted ? Hugeicons.eyeOff : Hugeicons.eye,
        label: showCompleted ? "Ocultar concluídas" : "Mostrar concluídas"
      ),
      PopoverMenuItem(id: "mode_cards", icon: Hugeicons.grid, label: "Balões",
                      selected: displayMode == "cards"),
      PopoverMenuItem(id: "mode_list", icon: Hugeicons.listView, label: "Lista",
                      selected: displayMode == "list"),
      PopoverMenuItem(id: "add_task", icon: Hugeicons.add01, label: "Nova tarefa"),
      PopoverMenuItem(id: "add_section", icon: Hugeicons.add01, label: "Nova seção"),
      PopoverMenuItem(id: "project_options", icon: Hugeicons.settings01, label: "Opções do projeto"),
    ]
  }

  private func handleToolbarAction(_ value: String?) {
    guard let value else { return }
    switch value {
    case "toggle_completed": showCompleted.toggle()
    case "mode_cards": displayMode = "cards"
    case "mode_list": displayMode = "list"
    case "add_task": showQuickAdd = true
    case "add_section": showNewSection = true
    case "project_options": showProjectOptions = true
    default: break
    }
  }

  private var rowInsets: EdgeInsets {
    isListMode
      ? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
      : EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func projectTaskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      style: isListMode ? .list : .card,
      showProject: false,
      onToggle: {
        HapticService.light()
        store.complete(task)
      },
      onTap: {
        detailRoute = TaskDetailRoute(taskId: task.id)
      },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub)
      },
      onSubtaskChanged: {
        _Concurrency.Task { await store.load() }
      }
    )
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onComplete: { store.complete(task) },
      onDuplicate: { store.duplicate(task) },
      onDelete: { store.delete(task) },
      onRefresh: { _Concurrency.Task { await store.load() } }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        HapticService.success()
        store.complete(task)
      } label: {
        Label("Concluir", systemImage: "checkmark")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { await store.postpone(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
