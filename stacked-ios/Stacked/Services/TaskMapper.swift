import Foundation
import SwiftUI

// Paridade lib/models/task.dart fromJson + TaskRowDTO
enum TaskMapper {
  static func mapList(_ rows: [TaskRowDTO]) -> [Task] {
    rows.map(mapRow)
  }

  static func mapRow(_ row: TaskRowDTO) -> Task {
    let subtasks = (row.subtasks ?? [])
      .sorted { ($0.ordem ?? 0) < ($1.ordem ?? 0) }
      .map(mapSubtask)

    let labels: [TaskLabel] = (row.task_labels ?? []).compactMap { tl in
      guard let label = tl.labels,
            let nome = label.nome, !nome.isEmpty
      else { return nil }
      return TaskLabel(
        id: label.id ?? "",
        name: nome,
        color: AppColors.parseHex(label.cor)
      )
    }

    let commentCount = row.task_comments?.first?.count ?? 0
    let due = parseDueDate(row.data_vencimento)
    let timeDisplay = row.hora.map { formatTimeDisplay($0) }

    return Task(
      id: row.id,
      title: row.titulo ?? "",
      description: row.descricao,
      project: row.projects?.nome ?? "Sem projeto",
      projectId: row.project_id,
      sectionId: row.section_id,
      priority: Priority.parse(row.prioridade),
      time: row.hora,
      timeDisplay: timeDisplay,
      labels: labels,
      subtasks: subtasks,
      dueDate: due,
      dueDateChipLabel: due.map { dueDateChipLabel(for: $0) },
      dueDateChipColor: due.map { dateColor(for: $0) },
      done: row.concluida ?? false,
      commentCount: commentCount,
      recurrence: row.recorrencia
    )
  }

  private static func mapSubtask(_ row: SubtaskRowDTO) -> Subtask {
    let due = parseDueDate(row.data_vencimento)
    return Subtask(
      id: row.id,
      taskId: nil,
      title: row.titulo ?? "",
      description: row.descricao,
      done: row.concluida ?? false,
      priority: Priority.parse(row.prioridade),
      order: row.ordem ?? 0,
      valor: row.valor,
      dueDate: due,
      dueDateChipLabel: due.map { dueDateChipLabel(for: $0) },
      dueDateChipColor: due.map { dateColor(for: $0) },
      labelIds: row.label_ids ?? []
    )
  }

  static func parseDueDate(_ raw: String?) -> Date? {
    guard let raw else { return nil }
    let str = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !str.isEmpty else { return nil }

    let cal = Calendar.current

    // YYYY-MM-DD — sempre dia civil local (paridade Flutter DateTime(y,m,d))
    if str.count >= 10 {
      let head = String(str.prefix(10))
      if head.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
        let parts = head.split(separator: "-")
        if parts.count == 3,
           let y = Int(parts[0]),
           let m = Int(parts[1]),
           let d = Int(parts[2]),
           let date = cal.date(from: DateComponents(year: y, month: m, day: d)) {
          return cal.startOfDay(for: date)
        }
      }
    }

    // ISO com hora — normaliza para início do dia local
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let internet = ISO8601DateFormatter()
    internet.formatOptions = [.withInternetDateTime]

    for formatter in [withFraction, internet] {
      if let date = formatter.date(from: str) {
        return cal.startOfDay(for: date)
      }
    }

    return nil
  }

  static func dateString(_ date: Date) -> String {
    let local = Calendar.current.startOfDay(for: date)
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .current
    return f.string(from: local)
  }

  /// Paridade today_screen — separa atrasadas vs hoje
  static func splitTodayPending(_ tasks: [Task], now: Date = Date()) -> (overdue: [Task], today: [Task]) {
    let todayStart = Calendar.current.startOfDay(for: now)
    var overdue: [Task] = []
    var today: [Task] = []
    for t in tasks {
      guard let due = t.dueDate else {
        today.append(t)
        continue
      }
      if due < todayStart { overdue.append(t) }
      else { today.append(t) }
    }
    return (overdue, today)
  }

  static func tomorrowISO(from now: Date = Date()) -> String {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!
    return dateString(tomorrow)
  }

  static func postponedDateISO(for task: Task, now: Date = Date()) -> String {
    let today = Calendar.current.startOfDay(for: now)
    guard let current = task.dueDate else {
      return tomorrowISO(from: now)
    }
    let due = Calendar.current.startOfDay(for: current)
    if due <= today {
      return tomorrowISO(from: now)
    }
    let next = Calendar.current.date(byAdding: .day, value: 1, to: due)!
    return dateString(next)
  }

  static func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }

  static func isSameDay(_ a: Date, _ b: Date) -> Bool {
    startOfDay(a) == startOfDay(b)
  }

  static func weekString(from date: Date = Date()) -> String {
    let end = Calendar.current.date(byAdding: .day, value: 7, to: startOfDay(date))!
    return dateString(end)
  }

  private static let weekdayLabels = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
  private static let monthLabels = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]

  static func dayLabel(for date: Date, now: Date = Date()) -> String {
    let today = startOfDay(now)
    let d = startOfDay(date)
    if d == today { return "Hoje" }
    if d == Calendar.current.date(byAdding: .day, value: 1, to: today) { return "Amanhã" }
    let weekday = Calendar.current.component(.weekday, from: date)
    let idx = (weekday + 5) % 7
    let month = Calendar.current.component(.month, from: date)
    let day = Calendar.current.component(.day, from: date)
    return "\(weekdayLabels[idx]), \(day) \(monthLabels[month - 1])"
  }

  static func dateColor(for date: Date, now: Date = Date()) -> Color {
    let today = startOfDay(now)
    let d = startOfDay(date)
    if d == today { return AppColors.dateDueToday }
    if d == Calendar.current.date(byAdding: .day, value: 1, to: today) { return AppColors.priorityMedium }
    let weekday = Calendar.current.component(.weekday, from: date)
    if weekday == 1 { return AppColors.priorityLow }
    if weekday == 2 { return AppColors.tagPurple }
    return Color(hex: 0x5FD3DC)
  }

  static func formatTimeDisplay(_ time: String) -> String {
    let parts = time.split(separator: ":")
    if parts.count >= 2 {
      return "\(parts[0]):\(parts[1])"
    }
    return time
  }

  private static let dueDateMonthLabels = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]

  /// Paridade TaskMetaLine.dueDateChipLabel — centralizado para memoização no mapRow.
  static func dueDateChipLabel(for date: Date, now: Date = Date()) -> String {
    let today = startOfDay(now)
    let due = startOfDay(date)
    if due == today { return "Hoje" }
    let day = Calendar.current.component(.day, from: date)
    let month = Calendar.current.component(.month, from: date)
    return "\(day) \(dueDateMonthLabels[month - 1])"
  }

  static func groupTasksByDay(_ tasks: [Task]) -> [(day: Date, tasks: [Task])] {
    var grouped: [Date: [Task]] = [:]
    for task in tasks {
      guard let due = task.dueDate else { continue }
      let day = startOfDay(due)
      grouped[day, default: []].append(task)
    }
    return grouped.keys.sorted().map { ($0, grouped[$0]!) }
  }
}
