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

  var body: some View {
    let c = theme.colors

    InboxScreenBody(
      colors: c,
      showCompleted: showCompleted,
      useUIKitTaskList: useUIKitTaskList,
      displayMode: displayMode,
      reduceMotion: reduceMotion,
      completedExpanded: $completedExpanded,
      allowRowHeavyWork: allowRowHeavyWork,
      detailRoute: $detailRoute,
      subtaskDetailRoute: $subtaskDetailRoute,
      taskDetailZoom: taskDetailZoom
    )
    .stackedTabletCentered()
    .background(c.background)
    .stackedListRowWorkGate($allowRowHeavyWork)
    .taskDetailCover(item: $detailRoute, namespace: taskDetailZoom, onDismiss: {
      _Concurrency.Task {
        await TaskDetailDismissRefresh.afterDismiss(tab: .inbox) {
          await store.loadInbox()
          await store.loadToday()
        }
      }
    }) { route in
      TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot) { await store.loadInbox() }
      }
      .environment(ThemeManager.shared)
    }
  }
}

// MARK: - Screen body (prefersUIKitList + subtitle)

private struct InboxScreenBody: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let useUIKitTaskList: Bool
  let displayMode: ProjectDisplayMode
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  private var prefersUIKitList: Bool {
    useUIKitTaskList
      && !store.inboxLoading
      && store.inboxError == nil
      && (!store.inboxPending.isEmpty || (showCompleted && !store.inboxCompleted.isEmpty))
  }

  private var subtitle: String {
    let count = store.inboxPending.count
    return "\(count) \(count == 1 ? "tarefa" : "tarefas")"
  }

  var body: some View {
    Group {
      if prefersUIKitList {
        InboxUIKitListContent(
          subtitle: subtitle,
          colors: colors,
          showCompleted: showCompleted,
          displayMode: displayMode,
          reduceMotion: reduceMotion,
          completedExpanded: $completedExpanded,
          detailRoute: $detailRoute,
          subtaskDetailRoute: $subtaskDetailRoute
        )
      } else {
        InboxSwiftUIListContent(
          subtitle: subtitle,
          colors: colors,
          showCompleted: showCompleted,
          displayMode: displayMode,
          reduceMotion: reduceMotion,
          completedExpanded: $completedExpanded,
          allowRowHeavyWork: allowRowHeavyWork,
          detailRoute: $detailRoute,
          subtaskDetailRoute: $subtaskDetailRoute,
          taskDetailZoom: taskDetailZoom
        )
      }
    }
  }
}

// MARK: - UIKit list (pending/completed arrays only)

private struct InboxUIKitListContent: View {
  @State private var store = TaskStore.shared

  let subtitle: String
  let colors: AppThemeColors
  let showCompleted: Bool
  let displayMode: ProjectDisplayMode
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?

  private var cardInsets: EdgeInsets { displayMode.taskListRowInsets }

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

  var body: some View {
    UIKitHostedTaskList(
      sections: inboxUIKitSections,
      showProject: true,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
      rowInsets: cardInsets,
      background: colors.background,
      leadingChrome: {
        AnyView(
          TaskListScreenHeader(
            title: "Inbox",
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
      onRefresh: { _Concurrency.Task { await store.loadInbox() } },
      onPostpone: { task in _Concurrency.Task { try? await store.postponeInbox(task) } }
    )
    .stackedScrollEdgeChrome()
  }
}

// MARK: - SwiftUI list shell

private struct InboxSwiftUIListContent: View {
  @State private var store = TaskStore.shared

  let subtitle: String
  let colors: AppThemeColors
  let showCompleted: Bool
  let displayMode: ProjectDisplayMode
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  private var isEmpty: Bool {
    !store.inboxLoading
      && store.inboxError == nil
      && store.inboxPending.isEmpty
      && (store.inboxCompleted.isEmpty || !showCompleted)
  }

  var body: some View {
    if isEmpty {
      ScrollView {
        VStack(spacing: 0) {
          TaskListScreenHeader(
            title: "Inbox",
            subtitle: subtitle,
            showCompletedKey: ShowCompletedPreferences.inboxKey,
            showCompletedDefault: false
          )
          .padding(.top, 4)
          .padding(.bottom, 8)

          EmptyStateView(
            illustration: .inboxZero,
            title: "Tudo certo",
            subtitle: "Sua caixa de entrada está vazia — sem pendências soltas por aqui."
          )
          .stackedStandaloneEmptyState()
          .frame(minHeight: 360)
        }
        .frame(maxWidth: .infinity)
      }
      .scrollContentBackground(.hidden)
      .refreshable { await store.loadInbox() }
    } else {
      List {
        Section {
          TaskListScreenHeader(
            title: "Inbox",
            subtitle: subtitle,
            showCompletedKey: ShowCompletedPreferences.inboxKey,
            showCompletedDefault: false
          )
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowBackground(Color.clear)
        }

        InboxSwiftUIStatusOrRows(
          colors: colors,
          showCompleted: showCompleted,
          displayMode: displayMode,
          reduceMotion: reduceMotion,
          completedExpanded: $completedExpanded,
          allowRowHeavyWork: allowRowHeavyWork,
          detailRoute: $detailRoute,
          subtaskDetailRoute: $subtaskDetailRoute,
          taskDetailZoom: taskDetailZoom
        )
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .stackedListTailInset()
      .refreshable { await store.loadInbox() }
    }
  }
}

// MARK: - Loading/error vs pending rows

private struct InboxSwiftUIStatusOrRows: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let displayMode: ProjectDisplayMode
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  var body: some View {
    if store.inboxLoading {
      Section {
        ProgressView()
          .tint(colors.accent)
          .frame(maxWidth: .infinity)
          .listRowSeparator(.hidden)
          .listSectionSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    } else if let err = store.inboxError {
      Section {
        LoadErrorView(message: err) {
          _Concurrency.Task { await store.loadInbox() }
        }
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    } else {
      InboxPendingRows(
        colors: colors,
        showCompleted: showCompleted,
        displayMode: displayMode,
        reduceMotion: reduceMotion,
        completedExpanded: $completedExpanded,
        allowRowHeavyWork: allowRowHeavyWork,
        detailRoute: $detailRoute,
        subtaskDetailRoute: $subtaskDetailRoute,
        taskDetailZoom: taskDetailZoom
      )
    }
  }
}

private struct InboxPendingRows: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let displayMode: ProjectDisplayMode
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  private var cardInsets: EdgeInsets { displayMode.taskListRowInsets }

  var body: some View {
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
              flatSubtaskQueue: displayMode.flatSubtaskQueue,
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

  @ViewBuilder
  private func taskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
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
      onRefresh: { _Concurrency.Task { await store.loadInbox() } },
      onPostpone: { _Concurrency.Task { try? await store.postponeInbox(task) } }
    )
  }
}
