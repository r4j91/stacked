import Foundation
import SwiftUI

struct TaskDetailRoute: Identifiable, Equatable {
  let taskId: String
  var id: String { taskId }
}

struct SubtaskDetailRoute: Identifiable {
  let subtask: Subtask
  let parentTaskId: String
  let id: String

  init(subtask: Subtask, parentTaskId: String) {
    self.subtask = subtask
    self.parentTaskId = parentTaskId
    if let sid = subtask.id, !sid.isEmpty {
      id = sid
    } else {
      id = "\(parentTaskId):\(subtask.order)"
    }
  }
}

@MainActor
@Observable
final class TaskDetailViewModel {
  let taskId: String

  var title = ""
  var descriptionText = ""
  var done = false
  var priority: Priority?
  var dueDate: Date?
  var time: String?
  var projectId: String?
  var sectionId: String?
  var projectName = "Sem projeto"
  var selectedLabelIds: Set<String> = []
  var subtasks: [Subtask] = []
  var recurrence: String?
  var comments: [TaskComment] = []
  var newCommentText = ""
  var whatsappRoutine = false

  var allProjects: [Project] = []
  var allLabels: [TaskLabel] = []

  var isLoading = true
  var error: String?

  private var titleSaveTask: _Concurrency.Task<Void, Never>?
  private var descSaveTask: _Concurrency.Task<Void, Never>?
  private var subtaskReorderTask: _Concurrency.Task<Void, Never>?
  private var subtaskSortHoldId: String?
  private var loadGeneration = 0
  private var whatsappRoutineReady = false

  init(taskId: String) {
    self.taskId = taskId
  }

  func reloadLabels() async {
    allLabels = (try? await LabelRepository.shared.fetchLabels()) ?? []
  }

  func load() async {
    loadGeneration += 1
    let generation = loadGeneration
    isLoading = true
    error = nil
    do {
      async let taskReq = TaskRepository.shared.fetchTaskById(taskId)
      async let projectsReq = ProjectRepository.shared.fetchProjects()
      async let labelsReq = LabelRepository.shared.fetchLabels()
      async let commentsReq = CommentRepository.shared.fetchComments(taskId: taskId)
      guard let task = try await taskReq else {
        guard generation == loadGeneration else { return }
        error = "Tarefa não encontrada"
        isLoading = false
        return
      }
      guard generation == loadGeneration else { return }
      apply(task)
      allProjects = try await projectsReq
      guard generation == loadGeneration else { return }
      allLabels = try await labelsReq
      guard generation == loadGeneration else { return }
      comments = try await commentsReq
      guard generation == loadGeneration else { return }
      selectedLabelIds = Set(task.labels.map(\.id))
    } catch {
      guard generation == loadGeneration else { return }
      self.error = error.localizedDescription
    }
    guard generation == loadGeneration else { return }
    isLoading = false
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    guard snapshot.parentTaskId == taskId else { return }
    SubtaskListPatch.apply(snapshot, to: &subtasks)
  }

  private func apply(_ task: Task) {
    title = task.title
    descriptionText = task.description ?? ""
    done = task.done
    priority = task.priority
    dueDate = task.dueDate
    time = task.time
    projectId = task.projectId
    sectionId = task.sectionId
    projectName = task.project
    if subtaskSortHoldId != nil, !subtasks.isEmpty {
      let sorted = task.subtasks
      subtasks = subtasks.map { local in
        sorted.first(where: { $0.id == local.id }) ?? local
      }
    } else {
      subtasks = task.subtasks
    }
    recurrence = task.recurrence
    whatsappRoutine = task.whatsappRoutine
    whatsappRoutineReady = true
    selectedLabelIds = Set(task.labels.map(\.id))
  }

  func setWhatsappRoutine(_ enabled: Bool) {
    whatsappRoutine = enabled
    guard whatsappRoutineReady else { return }
    _Concurrency.Task {
      await TaskDetailPersistence.autosaveWhatsappRoutine(taskId: taskId, enabled: enabled)
    }
  }

  var showsWhatsAppAction: Bool {
    whatsappRoutine && hasDescriptionText
  }

  private var hasDescriptionText: Bool {
    !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var whatsAppMessage: String {
    WhatsAppRoutineMessageBuilder.compose(
      taskTitle: title,
      dueDate: dueDate,
      description: descriptionText
    )
  }

  func onTitleChanged() {
    titleSaveTask?.cancel()
    titleSaveTask = _Concurrency.Task {
      try? await _Concurrency.Task.sleep(for: .milliseconds(400))
      guard !_Concurrency.Task.isCancelled else { return }
      await TaskDetailPersistence.autosaveTitle(taskId: taskId, title: title)
      TaskCalendarSync.syncAfterMutation(
        taskId: taskId,
        title: title,
        dueDate: dueDate,
        time: time,
        done: done
      )
    }
  }

  func onDescriptionChanged() {
    descSaveTask?.cancel()
    descSaveTask = _Concurrency.Task {
      try? await _Concurrency.Task.sleep(for: .milliseconds(500))
      guard !_Concurrency.Task.isCancelled else { return }
      await TaskDetailPersistence.autosaveDescription(taskId: taskId, description: descriptionText)
    }
  }

  func setPriority(_ p: Priority?) {
    priority = p
    _Concurrency.Task {
      await TaskDetailPersistence.autosavePriority(taskId: taskId, priority: p)
    }
  }

  func setDueDate(_ date: Date?, time timeDate: Date?) {
    dueDate = date
    if date == nil {
      time = nil
    } else if let timeDate {
      time = TaskMapper.timeString(from: timeDate)
    } else {
      time = nil
    }
    let iso = date.map { TaskMapper.dateString($0) }
    let savedTime = time
    _Concurrency.Task {
      await TaskDetailPersistence.autosaveDueDate(taskId: taskId, isoDate: iso)
      await TaskDetailPersistence.autosaveTime(taskId: taskId, time: savedTime)
      TaskCalendarSync.syncAfterMutation(
        taskId: taskId,
        title: title,
        dueDate: dueDate,
        time: savedTime,
        done: done
      )
      await NotificationService.shared.syncTaskNotification(
        id: taskId,
        title: title,
        dueDate: dueDate,
        time: savedTime
      )
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: Self.tabsAffected(dueDateISO: iso))
    }
  }

  func setProject(_ project: Project?) {
    projectId = project?.id
    projectName = project?.name ?? "Sem projeto"
    _Concurrency.Task {
      await TaskDetailPersistence.autosaveProject(taskId: taskId, projectId: project?.id)
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.inbox])
    }
  }

  func setLabels(_ ids: Set<String>) {
    selectedLabelIds = ids
    _Concurrency.Task {
      try? await LabelRepository.shared.setTaskLabels(taskId: taskId, labelIds: Array(ids))
    }
  }

  func toggleDone() {
    let becomingDone = !done
    done.toggle()
    HapticService.success()
    _Concurrency.Task {
      if becomingDone {
        let snapshot = Task(
          id: taskId,
          title: title,
          description: descriptionText.isEmpty ? nil : descriptionText,
          project: projectName,
          projectId: projectId,
          sectionId: sectionId,
          priority: priority,
          time: time,
          labels: allLabels.filter { selectedLabelIds.contains($0.id) },
          subtasks: subtasks,
          dueDate: dueDate,
          done: false,
          commentCount: comments.count,
          recurrence: recurrence
        )
        if let newId = try? await TaskRepository.shared.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
        }
        TaskCalendarSync.remove(taskId: taskId)
      } else {
        try? await TaskRepository.shared.toggleTaskDone(id: taskId, done: false)
        TaskCalendarSync.syncAfterMutation(
          taskId: taskId,
          title: title,
          dueDate: dueDate,
          time: time,
          done: done
        )
      }
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.today])
    }
  }

  func toggleSubtask(_ subtask: Subtask) {
    guard let id = subtask.id else { return }
    guard let i = subtasks.firstIndex(where: { $0.id == id }) else { return }
    let newDone = !subtask.done

    subtasks[i] = Subtask(
      id: subtask.id,
      taskId: subtask.taskId,
      title: subtask.title,
      description: subtask.description,
      done: newDone,
      priority: subtask.priority,
      order: subtask.order,
      valor: subtask.valor,
      dueDate: subtask.dueDate,
      time: subtask.time,
      labelIds: subtask.labelIds
    )

    subtaskReorderTask?.cancel()
    subtaskReorderTask = _Concurrency.Task { @MainActor [weak self] in
      guard let self else { return }
      if newDone {
        self.subtaskSortHoldId = id
        if !UIAccessibility.isReduceMotionEnabled {
          try? await _Concurrency.Task.sleep(for: AppMotion.subtaskCompleteReorderDelay)
        }
        guard !_Concurrency.Task.isCancelled else { return }
        self.subtaskSortHoldId = nil
        withAnimation(AppMotion.smooth) {
          self.subtasks = TaskMapper.sortSubtasksForDisplay(self.subtasks)
        }
      } else {
        self.subtaskSortHoldId = nil
        if UIAccessibility.isReduceMotionEnabled {
          self.subtasks = TaskMapper.sortSubtasksForDisplay(self.subtasks)
        } else {
          withAnimation(AppMotion.smooth) {
            self.subtasks = TaskMapper.sortSubtasksForDisplay(self.subtasks)
          }
        }
      }

      try? await SubtaskRepository.shared.toggleDone(id: id, done: newDone)
      if newDone {
        TaskCalendarSync.remove(subtaskId: id)
      } else if let synced = self.subtasks.first(where: { $0.id == id }) {
        TaskCalendarSync.sync(synced)
      }
    }
  }

  func addSubtask(title: String) async {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let order = subtasks.count
    do {
      let newId = try await SubtaskRepository.shared.createSubtask(
        taskId: taskId,
        title: trimmed,
        order: order
      )
      subtasks.append(Subtask(
        id: newId,
        taskId: taskId,
        title: trimmed,
        description: nil,
        done: false,
        priority: nil,
        order: order,
        valor: nil,
        dueDate: nil,
        time: nil,
        labelIds: []
      ))
    } catch {
      self.error = error.localizedDescription
    }
  }

  func deleteSubtask(_ sub: Subtask) async {
    guard let id = sub.id else { return }
    do {
      TaskCalendarSync.remove(subtaskId: id)
      try await SubtaskRepository.shared.deleteSubtask(id: id)
      subtasks.removeAll { $0.id == id }
    } catch {
      self.error = error.localizedDescription
    }
  }

  func deleteTask() async throws {
    for sub in subtasks {
      if let subId = sub.id {
        TaskCalendarSync.remove(subtaskId: subId)
      }
    }
    TaskCalendarSync.remove(taskId: taskId)
    try await TaskRepository.shared.deleteTask(id: taskId)
  }

  func setRecurrence(_ type: RecurrenceType?) {
    recurrence = RecurrenceCodec.json(for: type)
    let value = recurrence
    _Concurrency.Task {
      try? await TaskRepository.shared.updateRecurrence(id: taskId, value: value)
    }
  }

  func sendComment() async {
    let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    do {
      try await CommentRepository.shared.sendComment(taskId: taskId, text: text)
      newCommentText = ""
      comments = try await CommentRepository.shared.fetchComments(taskId: taskId)
      HapticService.saved()
    } catch {
      self.error = error.localizedDescription
    }
  }

  var recurrenceLabel: String {
    RecurrenceCodec.displayLabel(for: recurrence)
  }

  var recurrenceType: RecurrenceType? {
    RecurrenceCodec.type(from: recurrence)
  }

  var selectedLabels: [TaskLabel] {
    allLabels.filter { selectedLabelIds.contains($0.id) }
  }

  var dueDateLabel: String {
    guard let dueDate else { return "Sem data" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateStyle = .medium
    var label = f.string(from: dueDate)
    if let time, !time.isEmpty {
      label += " · \(TaskMapper.formatTimeDisplay(time))"
    }
    return label
  }

  var dueTimeDate: Date? {
    guard let dueDate, let time else { return nil }
    return TaskMapper.combinedDateTime(dueDate: dueDate, time: time)
  }

  private static func tabsAffected(dueDateISO: String?) -> [NavTab] {
    let today = TaskMapper.dateString(Date())
    guard let dueDateISO else { return [.inbox] }
    var tabs: [NavTab] = []
    if dueDateISO <= today { tabs.append(.today) }
    if dueDateISO > today { tabs.append(.upcoming) }
    return tabs
  }
}
