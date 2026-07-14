import Foundation
import UserNotifications
import Supabase
import os

// Paridade lib/services/notification_service.dart
@MainActor
final class NotificationService {
  static let shared = NotificationService()

  private static let dailySummaryId = "daily-summary"
  private static let logger = Logger(subsystem: "com.stacked.app", category: "Notifications")
  private static let previewCacheTTL: TimeInterval = 60
  /// iOS permite no máximo 64 notificações locais pendentes por app.
  private static let maxItemNotifications = 60

  private var previewCache: PreviewSnapshot?

  private init() {}

  struct PreviewSnapshot: Equatable {
    let items: [SchedulableNotificationItem]
    let diagnostics: NotificationDiagnostics
    let fetchedAt: Date

    var isFresh: Bool {
      Date().timeIntervalSince(fetchedAt) < NotificationService.previewCacheTTL
    }
  }

  var cachedPreview: PreviewSnapshot? {
    guard let previewCache, previewCache.isFresh else { return nil }
    return previewCache
  }

  func invalidatePreviewCache() {
    previewCache = nil
  }

  func prefetchPreview(limit: Int = 20) async {
    _ = await fetchPreviewSnapshot(limit: limit, forceRefreshData: false)
  }

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
      if settings.alertSetting == .disabled {
        return false
      }
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
    invalidatePreviewCache()
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
  ) async -> Bool {
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
  ) async -> Bool {
    guard await isEnabled() else { return false }

    guard let normalizedTime = TaskMapper.normalizeHora(time) else { return false }

    let now = Date()
    let cal = Calendar.current
    let today = cal.startOfDay(for: now)
    let due = cal.startOfDay(for: dueDate)
    let diff = cal.dateComponents([.day], from: today, to: due).day ?? 0
    guard diff >= 0 else { return false }

    guard let scheduled = TaskMapper.combinedDateTime(dueDate: dueDate, time: normalizedTime) else { return false }
    guard scheduled > now else { return false }

    let timeLabel = TaskMapper.formatTimeDisplay(normalizedTime)
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

    var components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
    components.second = 0
    components.calendar = cal
    components.timeZone = cal.timeZone
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: trigger
    )

    return await addNotificationRequest(request, identifier: identifier)
  }

  private func addNotificationRequest(_ request: UNNotificationRequest, identifier: String) async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
      try await center.add(request)
      return true
    } catch {
      Self.logger.error("Failed to schedule \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
      return false
    }
  }

  func syncTaskNotification(id: String, title: String, dueDate: Date?, time: String?) async {
    guard let dueDate, let time, !time.isEmpty else {
      await cancelTaskNotification(id: id)
      invalidatePreviewCache()
      return
    }
    guard await isEnabled() else {
      await cancelTaskNotification(id: id)
      invalidatePreviewCache()
      return
    }
    // NET_FASEC_ETAPA2 — agendar só esta tarefa (antes: rescheduleAllPending).
    // _ = await rescheduleAllPending()
    _ = await scheduleTaskNotification(id: id, title: title, dueDate: dueDate, time: time)
    invalidatePreviewCache()
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
    if done || dueDate == nil || time?.isEmpty != false {
      await cancelSubtaskNotification(id: id)
      invalidatePreviewCache()
      return
    }
    guard await isEnabled() else {
      await cancelSubtaskNotification(id: id)
      invalidatePreviewCache()
      return
    }
    // NET_FASEC_ETAPA2 — schedule individual (antes: rescheduleAllPending).
    // _ = await rescheduleAllPending()
    guard let dueDate else { return }
    _ = await scheduleSubtaskNotification(
      id: id,
      title: title,
      dueDate: dueDate,
      time: time ?? ""
    )
    invalidatePreviewCache()
  }

  func scheduleSubtaskNotification(
    id: String,
    title: String,
    dueDate: Date,
    time: String
  ) async -> Bool {
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

    _ = await addNotificationRequest(request, identifier: Self.dailySummaryId)
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

  struct RescheduleResult: Equatable {
    let totalEligible: Int
    let scheduled: Int
    let registered: Int
    let pendingAfter: Int
    let failureReason: String?
  }

  private struct SchedulableCandidate: Equatable {
    let identifier: String
    let entityId: String
    let kind: SchedulableNotificationItem.Kind
    let title: String
    let parentTitle: String?
    let dueDate: Date
    let time: String
    let scheduledAt: Date
  }

  @discardableResult
  func rescheduleAllPending() async -> RescheduleResult {
    guard NotificationPreferences.enabled else {
      return RescheduleResult(
        totalEligible: 0,
        scheduled: 0,
        registered: 0,
        pendingAfter: 0,
        failureReason: "Ative notificações em Ajustes → Notificações no Stacked."
      )
    }
    guard await hasSystemPermission() else {
      return RescheduleResult(
        totalEligible: 0,
        scheduled: 0,
        registered: 0,
        pendingAfter: 0,
        failureReason: "Permita alertas do Stacked em Ajustes → Notificações no iPhone."
      )
    }
    guard SupabaseService.client.auth.currentUser?.id != nil else {
      return RescheduleResult(
        totalEligible: 0,
        scheduled: 0,
        registered: 0,
        pendingAfter: 0,
        failureReason: "Sessão expirada — abra o app e tente de novo."
      )
    }

    do {
      let candidates = try await fetchSchedulableCandidates()
      let totalEligible = candidates.count
      let toSchedule = Array(candidates.prefix(Self.maxItemNotifications))
      let expectedIds = Set(toSchedule.map(\.identifier))

      await cancelAllScheduledItemNotifications()

      var scheduled = 0
      for candidate in toSchedule {
        let ok: Bool
        switch candidate.kind {
        case .task:
          ok = await scheduleTaskNotification(
            id: candidate.entityId,
            title: candidate.title,
            dueDate: candidate.dueDate,
            time: candidate.time
          )
        case .subtask:
          ok = await scheduleSubtaskNotification(
            id: candidate.entityId,
            title: candidate.title,
            dueDate: candidate.dueDate,
            time: candidate.time
          )
        }
        if ok { scheduled += 1 }
      }

      await removeOrphanScheduledItemNotifications(keeping: expectedIds)
      await scheduleDailySummaryIfNeeded()
      invalidatePreviewCache()

      let pendingIds = await pendingItemNotificationIdentifiers()
      let registered = expectedIds.intersection(pendingIds).count
      let pendingAfter = pendingIds.count

      let failureReason: String?
      if totalEligible == 0 {
        failureReason = "Nenhuma tarefa com data e hora futuras para agendar."
      } else if scheduled > 0, registered == 0 {
        failureReason = simulatorRescheduleHint()
      } else if scheduled > 0, registered < scheduled {
        failureReason = "Só \(registered) de \(scheduled) alertas ficaram no iOS."
      } else if totalEligible > Self.maxItemNotifications {
        failureReason = nil // sucesso parcial — mensagem informativa no sheet
      } else {
        failureReason = nil
      }

      return RescheduleResult(
        totalEligible: totalEligible,
        scheduled: scheduled,
        registered: registered,
        pendingAfter: pendingAfter,
        failureReason: failureReason
      )
    } catch {
      Self.logger.error("rescheduleAllPending failed: \(error.localizedDescription, privacy: .public)")
      return RescheduleResult(
        totalEligible: 0,
        scheduled: 0,
        registered: 0,
        pendingAfter: await pendingItemNotificationIdentifiers().count,
        failureReason: "Erro ao buscar tarefas: \(error.localizedDescription)"
      )
    }
  }

  private func fetchSchedulableCandidates() async throws -> [SchedulableCandidate] {
    struct Row: Decodable {
      let id: String
      let titulo: String?
      let data_vencimento: String?
      let hora: String?
    }

    struct SubtaskRow: Decodable {
      let id: String
      let titulo: String?
      let data_vencimento: String?
      let hora: String?
      let tasks: ParentRef?

      struct ParentRef: Decodable {
        let titulo: String?
      }
    }

    let today = TaskMapper.dateString(Date())
    let now = Date()

    let rows: [Row] = try await SupabaseService.client
      .from("tasks")
      .select("id, titulo, data_vencimento, hora")
      .eq("concluida", value: false)
      .gte("data_vencimento", value: today)
      .not("hora", operator: .is, value: "null")
      .execute()
      .value

    let subRows: [SubtaskRow] = try await SupabaseService.client
      .from("subtasks")
      .select("id, titulo, data_vencimento, hora, tasks(titulo)")
      .eq("concluida", value: false)
      .gte("data_vencimento", value: today)
      .not("hora", operator: .is, value: "null")
      .execute()
      .value

    var candidates: [SchedulableCandidate] = []
    candidates.reserveCapacity(rows.count + subRows.count)

    for row in rows {
      guard let due = TaskMapper.parseDueDate(row.data_vencimento) else { continue }
      guard let hora = TaskMapper.normalizeHora(row.hora) else { continue }
      guard let scheduled = TaskMapper.combinedDateTime(dueDate: due, time: hora), scheduled > now else { continue }
      let title = row.titulo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !title.isEmpty else { continue }
      candidates.append(SchedulableCandidate(
        identifier: taskIdentifier(row.id),
        entityId: row.id,
        kind: .task,
        title: title,
        parentTitle: nil,
        dueDate: due,
        time: hora,
        scheduledAt: scheduled
      ))
    }

    for row in subRows {
      guard let due = TaskMapper.parseDueDate(row.data_vencimento) else { continue }
      guard let hora = TaskMapper.normalizeHora(row.hora) else { continue }
      guard let scheduled = TaskMapper.combinedDateTime(dueDate: due, time: hora), scheduled > now else { continue }
      let title = row.titulo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !title.isEmpty else { continue }
      let parent = row.tasks?.titulo?.trimmingCharacters(in: .whitespacesAndNewlines)
      candidates.append(SchedulableCandidate(
        identifier: subtaskIdentifier(row.id),
        entityId: row.id,
        kind: .subtask,
        title: title,
        parentTitle: parent?.isEmpty == false ? parent : nil,
        dueDate: due,
        time: hora,
        scheduledAt: scheduled
      ))
    }

    return candidates.sorted { $0.scheduledAt < $1.scheduledAt }
  }

  private func simulatorRescheduleHint() -> String {
    #if targetEnvironment(simulator)
    return "O simulador não registrou os alertas. Abra Ajustes → Notificações → Stacked e ative \"Permitir Notificações\" e \"Alertas\". No iPhone físico costuma funcionar direto."
    #else
    return "O iPhone não registrou os alertas. Verifique Ajustes → Notificações → Stacked."
    #endif
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

  private func removeOrphanScheduledItemNotifications(keeping expectedIds: Set<String>) async {
    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let orphanIds = pending
      .map(\.identifier)
      .filter { ($0.hasPrefix("task-") || $0.hasPrefix("subtask-")) && !expectedIds.contains($0) }
    guard !orphanIds.isEmpty else { return }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: orphanIds)
  }

  private func pendingItemNotificationIdentifiers() async -> Set<String> {
    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
    return Set(pending.map(\.identifier).filter { $0.hasPrefix("task-") || $0.hasPrefix("subtask-") })
  }

  func cancelAllNotifications() async {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }

  // MARK: - Preview helpers

  struct NotificationDiagnostics: Equatable {
    let userEnabled: Bool
    let systemAuthorized: Bool
    let pendingScheduledCount: Int
    let totalWithTime: Int
    let schedulingCap: Int

    var canSchedule: Bool { userEnabled && systemAuthorized }
  }

  func fetchDiagnostics(totalWithTime: Int = 0) async -> NotificationDiagnostics {
    let pending = await pendingItemNotificationIdentifiers()
    return NotificationDiagnostics(
      userEnabled: NotificationPreferences.enabled,
      systemAuthorized: await hasSystemPermission(),
      pendingScheduledCount: pending.count,
      totalWithTime: totalWithTime,
      schedulingCap: Self.maxItemNotifications
    )
  }

  /// Pede permissão do iOS (se necessário) e reagenda tudo.
  func requestPermissionAndReschedule() async -> Bool {
    let granted = await requestPermission()
    if granted {
      NotificationPreferences.enabled = true
      await rescheduleAllPending()
    }
    invalidatePreviewCache()
    return granted
  }

  /// Lista + diagnóstico para o sheet "Próximas" — leve, com cache curto.
  /// O status no iOS (`isRegisteredWithSystem`) é sempre recalculado; só a lista do Supabase usa cache.
  func fetchPreviewSnapshot(limit: Int = 20, forceRefreshData: Bool = false) async -> PreviewSnapshot {
    let candidates: [SchedulableCandidate]
    if !forceRefreshData, let cached = previewCache, cached.isFresh {
      candidates = (try? await fetchSchedulableCandidates()) ?? []
    } else {
      candidates = (try? await fetchSchedulableCandidates()) ?? []
    }

    let pendingIds = await isEnabled() ? await pendingItemNotificationIdentifiers() : Set<String>()
    let capIds = Set(candidates.prefix(Self.maxItemNotifications).map(\.identifier))

    let items = candidates.prefix(limit).map { candidate in
      SchedulableNotificationItem(
        id: candidate.identifier,
        kind: candidate.kind,
        title: candidate.title,
        parentTitle: candidate.parentTitle,
        dueDate: candidate.dueDate,
        time: candidate.time,
        scheduledAt: candidate.scheduledAt,
        isWithinSchedulingCap: capIds.contains(candidate.identifier),
        isRegisteredWithSystem: pendingIds.contains(candidate.identifier)
      )
    }

    let diagnostics = await fetchDiagnostics(totalWithTime: candidates.count)
    let snapshot = PreviewSnapshot(items: Array(items), diagnostics: diagnostics, fetchedAt: Date())
    previewCache = snapshot
    return snapshot
  }

  /// Item exibido no sheet "Próximas" (tarefa ou subtarefa com data+hora futuras).
  struct SchedulableNotificationItem: Identifiable, Equatable {
    enum Kind: Equatable { case task, subtask }

    let id: String
    let kind: Kind
    let title: String
    /// Título da tarefa pai — só em subtarefas.
    let parentTitle: String?
    let dueDate: Date
    let time: String
    let scheduledAt: Date
    /// Dentro dos 60 alertas mais próximos que o iOS aceita agendar de uma vez.
    let isWithinSchedulingCap: Bool
    /// `true` quando o identificador existe em `UNUserNotificationCenter`.
    let isRegisteredWithSystem: Bool

    func withStatus(registered: Bool, withinCap: Bool) -> SchedulableNotificationItem {
      SchedulableNotificationItem(
        id: id,
        kind: kind,
        title: title,
        parentTitle: parentTitle,
        dueDate: dueDate,
        time: time,
        scheduledAt: scheduledAt,
        isWithinSchedulingCap: withinCap,
        isRegisteredWithSystem: registered
      )
    }
  }

  func fetchSchedulableItems(limit: Int = 20, pendingIds: Set<String>? = nil) async -> [SchedulableNotificationItem] {
    guard let candidates = try? await fetchSchedulableCandidates() else { return [] }
    let resolvedPendingIds: Set<String>
    if let pendingIds {
      resolvedPendingIds = pendingIds
    } else if NotificationPreferences.enabled, await hasSystemPermission() {
      resolvedPendingIds = await pendingItemNotificationIdentifiers()
    } else {
      resolvedPendingIds = []
    }
    let capIds = Set(candidates.prefix(Self.maxItemNotifications).map(\.identifier))

    return candidates.prefix(limit).map { candidate in
      SchedulableNotificationItem(
        id: candidate.identifier,
        kind: candidate.kind,
        title: candidate.title,
        parentTitle: candidate.parentTitle,
        dueDate: candidate.dueDate,
        time: candidate.time,
        scheduledAt: candidate.scheduledAt,
        isWithinSchedulingCap: capIds.contains(candidate.identifier),
        isRegisteredWithSystem: resolvedPendingIds.contains(candidate.identifier)
      )
    }
  }

  @available(*, deprecated, message: "Use fetchSchedulableItems — inclui subtarefas.")
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
