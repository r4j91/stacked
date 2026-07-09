import Foundation

/// Subtarefa com data de vencimento exibida em Hoje / Em breve / calendário.
struct SubtaskScheduleEntry: Identifiable, Equatable {
  let subtask: Subtask
  let parent: Task

  var id: String {
    if let sid = subtask.id, !sid.isEmpty { return "subtask-\(sid)" }
    return "subtask-\(parent.id):\(subtask.order)"
  }
}

/// Item unificado para Hoje / Em breve — tarefa, subtarefa com data ou compromisso do Calendário.
enum ScheduleItem: Identifiable, Equatable {
  case task(Task)
  case subtask(SubtaskScheduleEntry)
  case calendarEvent(CalendarEvent)

  var id: String {
    switch self {
    case .task(let task): "task-\(task.id)"
    case .subtask(let entry): entry.id
    case .calendarEvent(let event): "event-\(event.id)"
    }
  }

  var day: Date {
    switch self {
    case .task(let task):
      task.dueDate.map(TaskMapper.startOfDay) ?? TaskMapper.startOfDay(Date())
    case .subtask(let entry):
      entry.subtask.dueDate.map(TaskMapper.startOfDay) ?? TaskMapper.startOfDay(Date())
    case .calendarEvent(let event):
      event.day
    }
  }

  /// Chave de ordenação dentro do dia — eventos/tarefas com hora primeiro.
  var sortDate: Date {
    switch self {
    case .task(let task):
      if let due = task.dueDate, let time = task.time,
         let combined = TaskMapper.combinedDateTime(dueDate: due, time: time) {
        return combined
      }
      return day.addingTimeInterval(60 * 60 * 24 - 1)
    case .subtask(let entry):
      if let due = entry.subtask.dueDate, let time = entry.subtask.time,
         let combined = TaskMapper.combinedDateTime(dueDate: due, time: time) {
        return combined
      }
      return day.addingTimeInterval(60 * 60 * 24 - 1)
    case .calendarEvent(let event):
      return event.isAllDay ? day : event.startDate
    }
  }

  var hasTimedSlot: Bool {
    switch self {
    case .task(let task):
      task.time != nil && !(task.time?.isEmpty ?? true)
    case .subtask(let entry):
      entry.subtask.time != nil && !(entry.subtask.time?.isEmpty ?? true)
    case .calendarEvent(let event):
      !event.isAllDay
    }
  }
}
