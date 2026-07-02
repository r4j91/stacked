import Foundation
import SwiftUI

struct TaskDetailRoute: Identifiable, Equatable {
  let taskId: String
  var id: String { taskId }
}

struct SubtaskDetailRoute: Identifiable {
  let subtask: Subtask
  var id: String { subtask.idOrFallback }
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

  init(taskId: String) {
    self.taskId = taskId
  }

  func load() async {
    isLoading = true
    error = nil
    do {
      async let taskReq = TaskRepository.shared.fetchTaskById(taskId)
      async let projectsReq = ProjectRepository.shared.fetchProjects()
      async let labelsReq = LabelRepository.shared.fetchLabels()
      async let commentsReq = CommentRepository.shared.fetchComments(taskId: taskId)
      guard let task = try await taskReq else {
        error = "Tarefa não encontrada"
        isLoading = false
        return
      }
      apply(task)
      allProjects = try await projectsReq
      allLabels = try await labelsReq
      comments = try await commentsReq
      selectedLabelIds = Set(task.labels.map(\.id))
    } catch {
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  private func apply(_ task: Task) {
    title = task.title
    descriptionText = task.description ?? ""
    done = task.done
    priority = task.priority
    dueDate = task.dueDate
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

  func setDueDate(_ date: Date?) {
    dueDate = date
    let iso = date.map { TaskMapper.dateString($0) }
    _Concurrency.Task {
      await TaskDetailPersistence.autosaveDueDate(taskId: taskId, isoDate: iso)
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
    return f.string(from: dueDate)
  }
}
