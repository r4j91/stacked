import Foundation
import UserNotifications
import Supabase

// Paridade lib/services/notification_service.dart
@MainActor
final class NotificationService {
  static let shared = NotificationService()

  private static let dailySummaryId = "daily-summary"

  private init() {}

  // MARK: - Permission & preferences

  var isUserEnabled: Bool {
    NotificationPreferences.enabled
  }

  func isEnabled() async -> Bool {
    guard NotificationPreferences.enabled else { return false }
    return await hasSystemPermission()
  }

  func hasSystemPermission() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return true
    default:
      return false
    }
  }

  func requestPermission() async -> Bool {
    await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
  }

  func setEnabled(_ value: Bool) async {
    NotificationPreferences.enabled = value
    if !value {
      await cancelAllNotifications()
    } else {
      await rescheduleAllPending()
    }
  }

  func setDailySummaryEnabled(_ value: Bool) async {
    NotificationPreferences.dailySummary = value
    if value {
      await scheduleDailySummaryIfNeeded()
    } else {
      await cancelDailySummary()
    }
  }

  // MARK: - Scheduling

  func scheduleTaskNotification(
    id: String,
    title: String,
    dueDate: Date,
    time: String
  ) async {
    await scheduleNotification(
      identifier: taskIdentifier(id),
      title: title,
      dueDate: dueDate,
      time: time
    )
  }

  private func scheduleNotification(
    identifier: String,
    title: String,
    dueDate: Date,
    time: String
  ) async {
    guard await isEnabled() else { return }

    let now = Date()
    let cal = Calendar.current
    let today = cal.startOfDay(for: now)
    let due = cal.startOfDay(for: dueDate)
    let diff = cal.dateComponents([.day], from: today, to: due).day ?? 0
    guard diff >= 0 else { return }

    guard let scheduled = TaskMapper.combinedDateTime(dueDate: dueDate, time: time) else { return }
    guard scheduled > now else { return }

    let timeLabel = TaskMapper.formatTimeDisplay(time)
    let body: String
    switch diff {
    case 0:
      body = "Hoje às \(timeLabel)"
    case 1:
      body = "Amanhã às \(timeLabel)"
    default:
      body = "Vence em \(diff) dias às \(timeLabel)"
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: trigger
    )

    try? await UNUserNotificationCenter.current().add(request)
  }

  func syncTaskNotification(id: String, title: String, dueDate: Date?, time: String?) async {
    await cancelTaskNotification(id: id)
    guard let dueDate, let time, !time.isEmpty else { return }
    await scheduleTaskNotification(id: id, title: title, dueDate: dueDate, time: time)
  }

  func syncTaskNotification(task: Task) async {
    await syncTaskNotification(
      id: task.id,
      title: task.title,
      dueDate: task.dueDate,
      time: task.time
    )
  }

  func syncSubtaskNotification(
    id: String,
    title: String,
    dueDate: Date?,
    time: String?,
    done: Bool
  ) async {
    await cancelSubtaskNotification(id: id)
    guard !done else { return }
    guard let dueDate, let time, !time.isEmpty else { return }
    await scheduleSubtaskNotification(id: id, title: title, dueDate: dueDate, time: time)
  }

  func scheduleSubtaskNotification(
    id: String,
    title: String,
    dueDate: Date,
    time: String
  ) async {
    await scheduleNotification(
      identifier: subtaskIdentifier(id),
      title: title,
      dueDate: dueDate,
      time: time
    )
  }

  func scheduleDailySummary(taskCount: Int) async {
    guard await isEnabled() else { return }
    guard NotificationPreferences.dailySummary else { return }

    let cal = Calendar.current
    let now = Date()
    var scheduled = cal.date(
      bySettingHour: 8,
      minute: 0,
      second: 0,
      of: cal.startOfDay(for: now)
    ) ?? now
    if scheduled <= now {
      scheduled = cal.date(byAdding: .day, value: 1, to: scheduled) ?? scheduled
    }

    let content = UNMutableNotificationContent()
    content.title = "Resumo do dia"
    content.body = taskCount == 1
      ? "Você tem 1 tarefa para hoje"
      : "Você tem \(taskCount) tarefas para hoje"
    content.sound = .default

    let components = cal.dateComponents([.hour, .minute], from: scheduled)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(
      identifier: Self.dailySummaryId,
      content: content,
      trigger: trigger
    )

    try? await UNUserNotificationCenter.current().add(request)
  }

  func scheduleDailySummaryIfNeeded() async {
    guard NotificationPreferences.dailySummary else { return }
    guard await isEnabled() else { return }
    guard SupabaseService.client.auth.currentUser?.id != nil else { return }

    let today = TaskMapper.dateString(Date())
    struct IdRow: Decodable { let id: String }
    do {
      let rows: [IdRow] = try await SupabaseService.client
        .from("tasks")
        .select("id")
        .eq("concluida", value: false)
        .eq("data_vencimento", value: today)
        .execute()
        .value
      await cancelDailySummary()
      await scheduleDailySummary(taskCount: rows.count)
    } catch {
      // ignore — resumo é best-effort
    }
  }

  func rescheduleAllPending() async {
    guard await isEnabled() else { return }
    guard SupabaseService.client.auth.currentUser?.id != nil else { return }

    struct Row: Decodable {
      let id: String
      let titulo: String?
      let data_vencimento: String?
      let hora: String?
    }

    let today = TaskMapper.dateString(Date())

    do {
      let rows: [Row] = try await SupabaseService.client
        .from("tasks")
        .select("id, titulo, data_vencimento, hora")
        .eq("concluida", value: false)
        .gte("data_vencimento", value: today)
        .execute()
        .value

      let subRows: [Row] = try await SupabaseService.client
        .from("subtasks")
        .select("id, titulo, data_vencimento, hora")
        .eq("concluida", value: false)
        .gte("data_vencimento", value: today)
        .execute()
        .value

      await cancelAllScheduledItemNotifications()

      for row in rows {
        guard let due = TaskMapper.parseDueDate(row.data_vencimento) else { continue }
        guard let hora = row.hora, !hora.isEmpty else { continue }
        let title = row.titulo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { continue }
        await scheduleTaskNotification(id: row.id, title: title, dueDate: due, time: hora)
      }

      for row in subRows {
        guard let due = TaskMapper.parseDueDate(row.data_vencimento) else { continue }
        guard let hora = row.hora, !hora.isEmpty else { continue }
        let title = row.titulo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { continue }
        await scheduleSubtaskNotification(id: row.id, title: title, dueDate: due, time: hora)
      }

      await scheduleDailySummaryIfNeeded()
    } catch {
      // ignore — reagendamento é best-effort no cold start
    }
  }

  // MARK: - Cancel

  func cancelTaskNotification(id: String) async {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [taskIdentifier(id)])
  }

  func cancelSubtaskNotification(id: String) async {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [subtaskIdentifier(id)])
  }

  func cancelDailySummary() async {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [Self.dailySummaryId])
  }

  func cancelAllTaskNotifications() async {
    await cancelAllScheduledItemNotifications()
  }

  private func cancelAllScheduledItemNotifications() async {
    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let ids = pending
      .map(\.identifier)
      .filter { $0.hasPrefix("task-") || $0.hasPrefix("subtask-") }
    guard !ids.isEmpty else { return }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
  }

  func cancelAllNotifications() async {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }

  // MARK: - Preview helpers

  func fetchSchedulableTasks(limit: Int = 20) async -> [Task] {
    let all = (try? await TaskRepository.shared.fetchDatedPendingTasks()) ?? []
    let now = Date()
    return all
      .filter { task in
        guard let due = task.dueDate, let time = task.time, !time.isEmpty else { return false }
        guard let scheduled = TaskMapper.combinedDateTime(dueDate: due, time: time) else { return false }
        return scheduled > now
      }
      .prefix(limit)
      .map { $0 }
  }

  // MARK: - Identifiers (paridade Flutter _notifId)

  private func taskIdentifier(_ taskId: String) -> String {
    "task-\(taskId)"
  }

  private func subtaskIdentifier(_ subtaskId: String) -> String {
    "subtask-\(subtaskId)"
  }
}
