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
  var projectName = "Sem projeto"
  var selectedLabelIds: Set<String> = []
  var subtasks: [Subtask] = []
  var recurrence: String?
  var comments: [TaskComment] = []
  var newCommentText = ""

  var allProjects: [Project] = []
  var allLabels: [TaskLabel] = []

  var isLoading = true
  var error: String?

  private var titleSaveTask: _Concurrency.Task<Void, Never>?
  private var descSaveTask: _Concurrency.Task<Void, Never>?
  private var loadGeneration = 0

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
    projectName = task.project
    subtasks = task.subtasks
    recurrence = task.recurrence
    selectedLabelIds = Set(task.labels.map(\.id))
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
    }
  }

  func setProject(_ project: Project?) {
    projectId = project?.id
    projectName = project?.name ?? "Sem projeto"
    _Concurrency.Task {
      await TaskDetailPersistence.autosaveProject(taskId: taskId, projectId: project?.id)
    }
  }

  func setLabels(_ ids: Set<String>) {
    selectedLabelIds = ids
    _Concurrency.Task {
      try? await LabelRepository.shared.setTaskLabels(taskId: taskId, labelIds: Array(ids))
    }
  }

  func toggleDone() {
    done.toggle()
    HapticService.success()
    _Concurrency.Task {
      try? await TaskRepository.shared.toggleTaskDone(id: taskId, done: done)
      if done {
        TaskCalendarSync.remove(taskId: taskId)
      } else {
        TaskCalendarSync.syncAfterMutation(
          taskId: taskId,
          title: title,
          dueDate: dueDate,
          time: time,
          done: done
        )
      }
    }
  }

  func toggleSubtask(_ subtask: Subtask) {
    guard let id = subtask.id else { return }
    guard let i = subtasks.firstIndex(where: { $0.id == id }) else { return }
    subtasks[i] = Subtask(
      id: subtask.id,
      taskId: subtask.taskId,
      title: subtask.title,
      description: subtask.description,
      done: !subtask.done,
      priority: subtask.priority,
      order: subtask.order,
      valor: subtask.valor,
      dueDate: subtask.dueDate,
      labelIds: subtask.labelIds
    )
    let newDone = subtasks[i].done
    _Concurrency.Task {
      try? await SubtaskRepository.shared.toggleDone(id: id, done: newDone)
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
        labelIds: []
      ))
    } catch {
      self.error = error.localizedDescription
    }
  }

  func deleteSubtask(_ sub: Subtask) async {
    guard let id = sub.id else { return }
    do {
      try await SubtaskRepository.shared.deleteSubtask(id: id)
      subtasks.removeAll { $0.id == id }
    } catch {
      self.error = error.localizedDescription
    }
  }

  func deleteTask() async throws {
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
}
