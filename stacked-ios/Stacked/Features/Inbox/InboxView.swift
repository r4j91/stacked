import SwiftUI

// Paridade lib/screens/inbox_screen.dart
struct InboxView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(ShowCompletedPreferences.inboxKey) private var showCompleted = false
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue
  @State private var store = TaskStore.shared
  @State private var completedExpanded = false
  @State private var allowRowHeavyWork = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  private var displayMode: ProjectDisplayMode { ProjectDisplayMode.from(displayModeRaw) }

  private var prefersUIKitList: Bool {
    useUIKitTaskList
      && !store.inboxLoading
      && store.inboxError == nil
      && (!store.inboxPending.isEmpty || (showCompleted && !store.inboxCompleted.isEmpty))
  }

  private var cardInsets: EdgeInsets {
    displayMode.taskListRowInsets
  }

  var body: some View {
    let c = theme.colors
    let count = store.inboxPending.count
    let subtitle = "\(count) \(count == 1 ? "tarefa" : "tarefas")"

    Group {
      if prefersUIKitList {
        uikitInboxBody(subtitle: subtitle, colors: c)
      } else {
        swiftUIListBody(subtitle: subtitle, colors: c)
      }
    }
    .stackedTabletCentered()
    .background(c.background)
    .stackedListRowWorkGate($allowRowHeavyWork)
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task {
        await TaskDetailDismissRefresh.afterDismiss(tab: .inbox) {
          await store.loadInbox()
          await store.loadToday()
        }
      }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot) { await store.loadInbox() }
      }
      .environment(ThemeManager.shared)
    }
  }

  @ViewBuilder
  private func uikitInboxBody(subtitle: String, colors: AppThemeColors) -> some View {
    UIKitHostedTaskList(
      sections: inboxUIKitSections,
      showProject: true,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskPanel,
      rowInsets: cardInsets,
      background: colors.background,
      leadingChrome: {
        AnyView(
          TaskListScreenHeader(
            title: "Caixa de entrada",
            subtitle: subtitle,
            showCompletedKey: ShowCompletedPreferences.inboxKey,
            showCompletedDefault: false
          )
          .padding(.top, 4)
          .padding(.bottom, 8)
        )
      },
      onToggleSection: { id in
        if id == "completed" {
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            completedExpanded.toggle()
          }
        }
      },
      onToggle: { store.completeInbox($0) },
      onTap: { detailRoute = TaskDetailRoute(task: $0) },
      onSubtaskTap: { task, sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { store.applySubtaskPatch($0) },
      onSubtaskDeleted: { task, sub in store.removeSubtask(parentId: task.id, subtask: sub) },
      onEdit: { detailRoute = TaskDetailRoute(task: $0) },
      onComplete: { store.completeInbox($0) },
      onDuplicate: { store.duplicateInbox($0) },
      onDelete: { store.deleteInbox($0) },
      onRefresh: { _Concurrency.Task { await store.loadInbox() } }
    )
    .stackedScrollEdgeChrome()
  }

  private var inboxUIKitSections: [UIKitTaskSection] {
    var sections: [UIKitTaskSection] = []
    if !store.inboxPending.isEmpty {
      sections.append(UIKitTaskSection(id: "pending", title: nil, tasks: store.inboxPending))
    }
    if showCompleted, !store.inboxCompleted.isEmpty {
      sections.append(
        UIKitTaskSection(
          id: "completed",
          header: .completedToggle(count: store.inboxCompleted.count, expanded: completedExpanded),
          tasks: store.inboxCompleted,
          dimmed: true
        )
      )
    }
    return sections
  }

  @ViewBuilder
  private func swiftUIListBody(subtitle: String, colors: AppThemeColors) -> some View {
    List {
      Section {
        TaskListScreenHeader(
          title: "Caixa de entrada",
          subtitle: subtitle,
          showCompletedKey: ShowCompletedPreferences.inboxKey,
          showCompletedDefault: false
        )
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.inboxLoading {
        Section {
          ProgressView()
            .tint(colors.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.inboxError {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.loadInbox() }
          }
          .listRowBackground(Color.clear)
        }
      } else if store.inboxPending.isEmpty && (store.inboxCompleted.isEmpty || !showCompleted) {
        Section {
          EmptyStateView(
            illustration: .inboxZero,
            title: "Tudo certo",
            subtitle: "Sua caixa de entrada está vazia — sem pendências soltas por aqui."
          )
          .stackedListEmptyStateRow()
        }
      } else {
        Section {
          ForEach(store.inboxPending) { task in
            taskRow(task)
          }
        }

        if showCompleted && !store.inboxCompleted.isEmpty {
          Section {
            Button {
              AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { completedExpanded.toggle() }
            } label: {
              HStack {
                Text("Concluídas (\(store.inboxCompleted.count))")
                  .font(AppTypography.completedSectionHeader)
                  .foregroundStyle(colors.textSecondary)
                Spacer()
                Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                  .font(AppTypography.metaSmall.weight(.semibold))
                  .foregroundStyle(colors.textTertiary)
              }
            }
            .listRowBackground(Color.clear)

            if completedExpanded {
              ForEach(store.inboxCompleted) { task in
                TaskRow(
                  task: task,
                  style: displayMode.taskRowStyle,
                  flatSubtaskPanel: displayMode.flatSubtaskPanel,
                  deferHeavyWork: !allowRowHeavyWork
                ) { }
                  .opacity(0.7)
                  .listRowInsets(cardInsets)
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
              }
            }
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .stackedListTailInset()
    .refreshable { await store.loadInbox() }
  }

  @ViewBuilder
  private func taskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      style: displayMode.taskRowStyle,
      flatSubtaskPanel: displayMode.flatSubtaskPanel,
      deferHeavyWork: !allowRowHeavyWork,
      onToggle: {
      store.completeInbox(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(task: task)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
    }, onSubtaskChanged: { snapshot in
      store.applySubtaskPatch(snapshot)
    }, onSubtaskDeleted: { sub in
      store.removeSubtask(parentId: task.id, subtask: sub)
    })
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom, active: detailRoute?.taskId == task.id)
    .taskCompleteRemovalTransition()
    .listRowInsets(cardInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(task: task) },
      onComplete: { store.completeInbox(task) },
      onDuplicate: { store.duplicateInbox(task) },
      onDelete: { store.deleteInbox(task) },
      onRefresh: { _Concurrency.Task { await store.loadInbox() } }
    )
  }
}
