import Foundation

/// Item unificado para Hoje / Em breve — tarefa Stacked ou compromisso do Calendário.
enum ScheduleItem: Identifiable, Equatable {
  case task(Task)
  case calendarEvent(CalendarEvent)

  var id: String {
    switch self {
    case .task(let task): "task-\(task.id)"
    case .calendarEvent(let event): "event-\(event.id)"
    }
  }

  var day: Date {
    switch self {
    case .task(let task):
      task.dueDate.map(TaskMapper.startOfDay) ?? TaskMapper.startOfDay(Date())
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
    case .calendarEvent(let event):
      return event.isAllDay ? day : event.startDate
    }
  }

  var hasTimedSlot: Bool {
    switch self {
    case .task(let task):
      task.time != nil && !(task.time?.isEmpty ?? true)
    case .calendarEvent(let event):
      !event.isAllDay
    }
  }
}
