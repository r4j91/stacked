import EventKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class EventKitCalendarService {
  static let shared = EventKitCalendarService()

  static let stackedCalendarTitle = "Stacked"
  static let stackedTaskURLPrefix = "stacked://task/"
  static let stackedSubtaskURLPrefix = "stacked://subtask/"
  /// Duração visual no Calendário (30 min ≈ blocos legíveis; 1 min virava linha fina).
  private static let compactExportDuration: TimeInterval = 30 * 60
  private static let standardExportDuration: TimeInterval = 3600

  private let store = EKEventStore()
  private static let eventMapKey = "calendar_task_event_map"
  private static let subtaskEventMapKey = "calendar_subtask_event_map"
  private static let taskReminderMapKey = "calendar_task_reminder_map"
  private static let subtaskReminderMapKey = "calendar_subtask_reminder_map"
  private static let exportCalendarIdKey = "calendar_stacked_export_calendar_id"
  private static let exportReminderListIdKey = "calendar_stacked_export_reminder_list_id"

  private var cachedExportCalendar: EKCalendar?
  private var cachedExportReminderList: EKCalendar?

  private(set) var authorizationGranted = false
  private(set) var remindersAuthorizationGranted = false
  private(set) var writableCalendars: [EKCalendar] = []
  private(set) var importableCalendars: [EKCalendar] = []
  private(set) var isExportSyncing = false

  /// Índice em memória durante sync em lote — evita varrer o EventKit por tarefa.
  private var batchExportedEventIndex: [String: [EKEvent]]?

  private var eventMap: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: Self.eventMapKey) as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.eventMapKey) }
  }

  private var subtaskEventMap: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: Self.subtaskEventMapKey) as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.subtaskEventMapKey) }
  }

  private var taskReminderMap: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: Self.taskReminderMapKey) as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.taskReminderMapKey) }
  }

  private var subtaskReminderMap: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: Self.subtaskReminderMapKey) as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.subtaskReminderMapKey) }
  }

  private init() {
    refreshAuthorizationState()
    NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged,
      object: store,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      _Concurrency.Task { @MainActor in
        self.cachedExportCalendar = nil
        self.cachedExportReminderList = nil
        self.reloadCalendarLists()
        await self.notifyStoresToRefresh()
      }
    }
  }

  func refreshAuthorizationState() {
    let status = EKEventStore.authorizationStatus(for: .event)
    authorizationGranted = hasReadAccess(status)
    remindersAuthorizationGranted = hasRemindersAccess(EKEventStore.authorizationStatus(for: .reminder))
    reloadCalendarLists()
  }

  func requestAccess() async -> Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if hasReadAccess(status) || canWriteEvents(status) {
      authorizationGranted = hasReadAccess(status)
      reloadCalendarLists()
      return hasReadAccess(status) || canWriteEvents(status)
    }

    if #available(iOS 17.0, *), status == .denied || status == .restricted {
      return false
    }

    do {
      let granted: Bool
      if #available(iOS 17.0, *) {
        granted = try await store.requestFullAccessToEvents()
      } else {
        granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
          store.requestAccess(to: .event) { granted, error in
            if let error { continuation.resume(throwing: error) }
            else { continuation.resume(returning: granted) }
          }
        }
      }
      let newStatus = EKEventStore.authorizationStatus(for: .event)
      authorizationGranted = hasReadAccess(newStatus)
      reloadCalendarLists()
      return granted || canWriteEvents(newStatus)
    } catch {
      let newStatus = EKEventStore.authorizationStatus(for: .event)
      authorizationGranted = hasReadAccess(newStatus)
      reloadCalendarLists()
      return hasReadAccess(newStatus) || canWriteEvents(newStatus)
    }
  }

  func requestRemindersAccess() async -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    if hasRemindersAccess(status) {
      remindersAuthorizationGranted = true
      return true
    }

    if #available(iOS 17.0, *), status == .denied || status == .restricted {
      return false
    }

    do {
      let granted: Bool
      if #available(iOS 17.0, *) {
        granted = try await store.requestFullAccessToReminders()
      } else {
        granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
          store.requestAccess(to: .reminder) { granted, error in
            if let error { continuation.resume(throwing: error) }
            else { continuation.resume(returning: granted) }
          }
        }
      }
      let newStatus = EKEventStore.authorizationStatus(for: .reminder)
      remindersAuthorizationGranted = hasRemindersAccess(newStatus)
      return granted && remindersAuthorizationGranted
    } catch {
      let newStatus = EKEventStore.authorizationStatus(for: .reminder)
      remindersAuthorizationGranted = hasRemindersAccess(newStatus)
      return remindersAuthorizationGranted
    }
  }

  func reloadCalendarLists() {
    guard authorizationGranted || canWriteEvents() else {
      writableCalendars = []
      importableCalendars = []
      return
    }
    let all = store.calendars(for: .event)
    importableCalendars = all
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    writableCalendars = all.filter(\.allowsContentModifications)
  }

  // MARK: - Import

  func fetchEvents(from start: Date, to end: Date) -> [CalendarEvent] {
    guard CalendarPreferences.importEnabled, authorizationGranted else { return [] }
    let calendars = selectedImportCalendars()
    guard !calendars.isEmpty else { return [] }

    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
    return store.events(matching: predicate)
      .filter { !isStackedExportedEvent($0) }
      .map(mapEvent(_:))
      .sorted { $0.startDate < $1.startDate }
  }

  var calendarsAvailableForImport: [EKCalendar] {
    let excluded = exportCalendarIdentifiers()
    return importableCalendars.filter { cal in
      cal.title != Self.stackedCalendarTitle && !excluded.contains(cal.calendarIdentifier)
    }
  }

  func fetchTodayEvents(now: Date = Date()) -> [CalendarEvent] {
    let start = TaskMapper.startOfDay(now)
    let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
    return fetchEvents(from: start, to: end)
  }

  func fetchUpcomingEvents(from startDay: Date = Date(), horizonDays: Int = 120) -> [CalendarEvent] {
    let start = TaskMapper.startOfDay(startDay)
    let end = Calendar.current.date(byAdding: .day, value: horizonDays, to: start) ?? start.addingTimeInterval(86400 * Double(horizonDays))
    return fetchEvents(from: start, to: end)
  }

  // MARK: - Export

  func syncTask(_ task: Task) {
    guard CalendarPreferences.exportEnabled else { return }

    guard let due = task.dueDate, !task.done else {
      removeExportedTask(taskId: task.id)
      return
    }

    if CalendarPreferences.exportAsAllDay {
      guard canWriteEvents() else { return }
      removeReminder(forTaskId: task.id)
      syncCompactExportedTask(task, dueDate: due)
      return
    }

    guard canWriteEvents() else { return }
    removeReminder(forTaskId: task.id)

    if task.time == nil || task.time?.isEmpty == true {
      removeEvent(forTaskId: task.id)
      return
    }

    guard let time = task.time,
          let start = TaskMapper.combinedDateTime(dueDate: due, time: time) else {
      removeEvent(forTaskId: task.id)
      return
    }

    saveExportedEvent(
      itemId: task.id,
      title: task.title,
      start: start,
      end: start.addingTimeInterval(Self.standardExportDuration),
      isAllDay: false,
      urlPrefix: Self.stackedTaskURLPrefix,
      map: eventMap
    ) { [self] newMap in
      eventMap = newMap
    }
  }

  func syncSubtask(_ subtask: Subtask) {
    guard CalendarPreferences.exportEnabled else { return }
    guard let subtaskId = subtask.id else { return }

    guard let due = subtask.dueDate, !subtask.done else {
      removeExportedSubtask(subtaskId: subtaskId)
      return
    }

    if CalendarPreferences.exportAsAllDay {
      guard canWriteEvents() else { return }
      removeReminder(forSubtaskId: subtaskId)
      syncCompactExportedSubtask(subtask, subtaskId: subtaskId, dueDate: due)
      return
    }

    guard canWriteEvents() else { return }
    removeReminder(forSubtaskId: subtaskId)

    if subtask.time == nil || subtask.time?.isEmpty == true {
      removeEvent(forSubtaskId: subtaskId)
      return
    }

    guard let time = subtask.time,
          let start = TaskMapper.combinedDateTime(dueDate: due, time: time) else {
      removeEvent(forSubtaskId: subtaskId)
      return
    }

    saveExportedEvent(
      itemId: subtaskId,
      title: subtask.title,
      start: start,
      end: start.addingTimeInterval(Self.standardExportDuration),
      isAllDay: false,
      urlPrefix: Self.stackedSubtaskURLPrefix,
      map: subtaskEventMap
    ) { [self] newMap in
      subtaskEventMap = newMap
    }
  }

  func removeExportedTask(taskId: String) {
    removeEvent(forTaskId: taskId)
    removeReminder(forTaskId: taskId)
  }

  func removeExportedSubtask(subtaskId: String) {
    removeEvent(forSubtaskId: subtaskId)
    removeReminder(forSubtaskId: subtaskId)
  }

  func removeEvent(forTaskId taskId: String) {
    removeExportedEvent(itemId: taskId, map: eventMap) { [self] newMap in
      eventMap = newMap
    }
  }

  func removeEvent(forSubtaskId subtaskId: String) {
    removeExportedEvent(itemId: subtaskId, map: subtaskEventMap) { [self] newMap in
      subtaskEventMap = newMap
    }
  }

  func removeReminder(forTaskId taskId: String) {
    removeExportedReminder(itemId: taskId, map: taskReminderMap) { [self] newMap in
      taskReminderMap = newMap
    }
  }

  func removeReminder(forSubtaskId subtaskId: String) {
    removeExportedReminder(itemId: subtaskId, map: subtaskReminderMap) { [self] newMap in
      subtaskReminderMap = newMap
    }
  }

  func syncAllExportableTasks(runGlobalDedupe: Bool = true) async {
    guard CalendarPreferences.exportEnabled else { return }
    guard !isExportSyncing else { return }
    if !canWriteEvents() {
      _ = await requestAccess()
    }
    guard canWriteEvents() else { return }

    isExportSyncing = true
    defer {
      batchExportedEventIndex = nil
      isExportSyncing = false
    }

    purgeAllExportedReminders()
    if runGlobalDedupe {
      dedupeAllExportedEvents()
    }
    batchExportedEventIndex = buildExportedEventURLIndex()

    do {
      let tasks = try await TaskRepository.shared.fetchDatedPendingTasks()
      for (index, task) in tasks.enumerated() where !task.done {
        syncTask(task)
        if index.isMultiple(of: 5) { await _Concurrency.Task.yield() }
      }
      let subtasks = try await SubtaskRepository.shared.fetchDatedPendingScheduleEntries()
      for (index, entry) in subtasks.enumerated() where !entry.subtask.done {
        syncSubtask(entry.subtask)
        if index.isMultiple(of: 5) { await _Concurrency.Task.yield() }
      }
    } catch { }
  }

  /// Re-sincroniza export ao abrir o app (tarefas criadas antes de ligar export).
  func syncExportIfNeeded() async {
    guard CalendarPreferences.exportEnabled else { return }
    if !canWriteEvents() {
      _ = await requestAccess()
    }
    await syncAllExportableTasks()
  }

  func openInCalendar(_ event: CalendarEvent) {
    let start = event.startDate.timeIntervalSinceReferenceDate
    if let url = URL(string: "calshow:\(start)") {
      UIApplication.shared.open(url)
    }
  }

  // MARK: - Private

  private func hasReadAccess(_ status: EKAuthorizationStatus) -> Bool {
    if #available(iOS 17.0, *) {
      return status == .fullAccess
    }
    // Pre-iOS 17 `.authorized` (raw 3) — evita warning de depreciação no SDK novo.
    return status.rawValue == 3
  }

  private func canWriteEvents(_ status: EKAuthorizationStatus? = nil) -> Bool {
    let status = status ?? EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      return status == .fullAccess || status == .writeOnly
    }
    return status.rawValue == 3
  }

  private func hasRemindersAccess(_ status: EKAuthorizationStatus) -> Bool {
    if #available(iOS 17.0, *) {
      return status == .fullAccess
    }
    return status.rawValue == 3
  }

  private func canWriteReminders(_ status: EKAuthorizationStatus? = nil) -> Bool {
    let status = status ?? EKEventStore.authorizationStatus(for: .reminder)
    return hasRemindersAccess(status)
  }

  private func purgeAllExportedReminders() {
    let taskIds = Array(taskReminderMap.keys)
    for id in taskIds { removeReminder(forTaskId: id) }
    let subtaskIds = Array(subtaskReminderMap.keys)
    for id in subtaskIds { removeReminder(forSubtaskId: id) }
  }

  private func syncCompactExportedTask(_ task: Task, dueDate: Date) {
    guard let start = exportStartDate(dueDate: dueDate, time: task.time) else {
      removeEvent(forTaskId: task.id)
      return
    }
    saveExportedEvent(
      itemId: task.id,
      title: task.title,
      start: start,
      end: start.addingTimeInterval(Self.compactExportDuration),
      isAllDay: false,
      urlPrefix: Self.stackedTaskURLPrefix,
      map: eventMap
    ) { [self] newMap in
      eventMap = newMap
    }
  }

  private func syncCompactExportedSubtask(_ subtask: Subtask, subtaskId: String, dueDate: Date) {
    guard let start = exportStartDate(dueDate: dueDate, time: subtask.time) else {
      removeEvent(forSubtaskId: subtaskId)
      return
    }
    saveExportedEvent(
      itemId: subtaskId,
      title: subtask.title,
      start: start,
      end: start.addingTimeInterval(Self.compactExportDuration),
      isAllDay: false,
      urlPrefix: Self.stackedSubtaskURLPrefix,
      map: subtaskEventMap
    ) { [self] newMap in
      subtaskEventMap = newMap
    }
  }

  private func exportStartDate(dueDate: Date, time: String?) -> Date? {
    if let time, !time.isEmpty {
      return TaskMapper.combinedDateTime(dueDate: dueDate, time: time)
    }
    return TaskMapper.startOfDay(dueDate)
  }

  private func syncTaskReminder(_ task: Task, dueDate: Date) {
    saveExportedReminder(
      itemId: task.id,
      title: task.title,
      dueDate: dueDate,
      time: task.time,
      urlPrefix: Self.stackedTaskURLPrefix,
      map: taskReminderMap
    ) { [self] newMap in
      taskReminderMap = newMap
    }
  }

  private func syncSubtaskReminder(_ subtask: Subtask, subtaskId: String, dueDate: Date) {
    saveExportedReminder(
      itemId: subtaskId,
      title: subtask.title,
      dueDate: dueDate,
      time: subtask.time,
      urlPrefix: Self.stackedSubtaskURLPrefix,
      map: subtaskReminderMap
    ) { [self] newMap in
      subtaskReminderMap = newMap
    }
  }

  private func dueDateComponents(dueDate: Date, time: String?) -> DateComponents {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
    if let time, !time.isEmpty,
       let combined = TaskMapper.combinedDateTime(dueDate: dueDate, time: time) {
      let timeParts = Calendar.current.dateComponents([.hour, .minute], from: combined)
      components.hour = timeParts.hour
      components.minute = timeParts.minute
      components.second = 0
    }
    return components
  }

  private func selectedImportCalendars() -> [EKCalendar] {
    let excludedIds = exportCalendarIdentifiers()
    let withoutStacked = importableCalendars.filter { cal in
      if cal.title == Self.stackedCalendarTitle { return false }
      if excludedIds.contains(cal.calendarIdentifier) { return false }
      return true
    }
    let selected = CalendarPreferences.selectedCalendarIDs
    if selected.isEmpty { return withoutStacked }
    return withoutStacked.filter { selected.contains($0.calendarIdentifier) }
  }

  /// IDs de calendários usados só para exportar — nunca importar de volta.
  private func exportCalendarIdentifiers() -> Set<String> {
    var ids = Set<String>()
    if let savedId = UserDefaults.standard.string(forKey: Self.exportCalendarIdKey) {
      ids.insert(savedId)
    }
    if let export = resolveExportCalendar() {
      ids.insert(export.calendarIdentifier)
    }
    for cal in store.calendars(for: .event) where cal.title == Self.stackedCalendarTitle {
      ids.insert(cal.calendarIdentifier)
    }
    return ids
  }

  /// Calendário "Stacked" ou fallback para o calendário padrão do sistema (simulador).
  private func resolveExportCalendar() -> EKCalendar? {
    if let cachedExportCalendar { return cachedExportCalendar }

    if let savedId = UserDefaults.standard.string(forKey: Self.exportCalendarIdKey),
       let saved = store.calendar(withIdentifier: savedId) {
      cachedExportCalendar = saved
      return saved
    }

    if let existing = store.calendars(for: .event).first(where: { $0.title == Self.stackedCalendarTitle }) {
      cacheExportCalendar(existing)
      return existing
    }

    if let created = createStackedCalendar() {
      cacheExportCalendar(created)
      return created
    }

    if let fallback = store.defaultCalendarForNewEvents ?? writableCalendars.first {
      cacheExportCalendar(fallback)
      return fallback
    }

    return nil
  }

  private func createStackedCalendar() -> EKCalendar? {
    guard let source = preferredWritableSource() else { return nil }

    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.title = Self.stackedCalendarTitle
    calendar.cgColor = UIColor(Color(hex: 0x5FD3DC)).cgColor
    calendar.source = source

    do {
      try store.saveCalendar(calendar, commit: true)
      return calendar
    } catch {
      return nil
    }
  }

  private func resolveExportReminderList() -> EKCalendar? {
    if let cachedExportReminderList { return cachedExportReminderList }

    if let savedId = UserDefaults.standard.string(forKey: Self.exportReminderListIdKey),
       let saved = store.calendar(withIdentifier: savedId) {
      cachedExportReminderList = saved
      return saved
    }

    if let existing = store.calendars(for: .reminder).first(where: { $0.title == Self.stackedCalendarTitle }) {
      cacheExportReminderList(existing)
      return existing
    }

    if let created = createStackedReminderList() {
      cacheExportReminderList(created)
      return created
    }

    if let fallback = store.defaultCalendarForNewReminders() {
      cacheExportReminderList(fallback)
      return fallback
    }

    return nil
  }

  private func createStackedReminderList() -> EKCalendar? {
    guard let source = preferredWritableSource() else { return nil }

    let list = EKCalendar(for: .reminder, eventStore: store)
    list.title = Self.stackedCalendarTitle
    list.cgColor = UIColor(Color(hex: 0x5FD3DC)).cgColor
    list.source = source

    do {
      try store.saveCalendar(list, commit: true)
      return list
    } catch {
      return nil
    }
  }

  private func cacheExportReminderList(_ list: EKCalendar) {
    cachedExportReminderList = list
    UserDefaults.standard.set(list.calendarIdentifier, forKey: Self.exportReminderListIdKey)
  }

  private func preferredWritableSource() -> EKSource? {
    store.defaultCalendarForNewEvents?.source
      ?? store.sources.first(where: { $0.sourceType == .local })
      ?? store.sources.first(where: { $0.sourceType == .calDAV })
      ?? store.sources.first(where: { $0.sourceType == .mobileMe })
      ?? store.sources.first
  }

  private func cacheExportCalendar(_ calendar: EKCalendar) {
    cachedExportCalendar = calendar
    UserDefaults.standard.set(calendar.calendarIdentifier, forKey: Self.exportCalendarIdKey)
  }

  private func isStackedExportedEvent(_ event: EKEvent) -> Bool {
    if exportCalendarIdentifiers().contains(event.calendar.calendarIdentifier) { return true }
    if event.calendar.title == Self.stackedCalendarTitle { return true }
    if let url = event.url?.absoluteString {
      if url.hasPrefix(Self.stackedTaskURLPrefix) { return true }
      if url.hasPrefix(Self.stackedSubtaskURLPrefix) { return true }
    }
    return false
  }

  /// Remove cópias globais de eventos exportados (mesmo `stacked://` URL).
  private func dedupeAllExportedEvents() {
    guard let exportCalendar = resolveExportCalendar() else { return }
    let byURL = buildExportedEventURLIndex()

    let preferredId = exportCalendar.calendarIdentifier
    var didChange = false
    for group in byURL.values where group.count > 1 {
      let canonical = group.first(where: { $0.calendar.calendarIdentifier == preferredId }) ?? group[0]
      for duplicate in group where duplicate.eventIdentifier != canonical.eventIdentifier {
        try? store.remove(duplicate, span: .thisEvent, commit: false)
        didChange = true
      }
    }
    if didChange { try? store.commit() }
    dedupeLegacyExportedEvents(in: exportCalendar)
  }

  private func buildExportedEventURLIndex() -> [String: [EKEvent]] {
    let cal = Calendar.current
    let start = cal.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    let end = cal.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: store.calendars(for: .event))
    var byURL: [String: [EKEvent]] = [:]
    for event in store.events(matching: predicate) {
      guard let url = event.url?.absoluteString,
            url.hasPrefix(Self.stackedTaskURLPrefix) || url.hasPrefix(Self.stackedSubtaskURLPrefix) else { continue }
      byURL[url, default: []].append(event)
    }
    return byURL
  }

  /// Eventos antigos exportados sem `stacked://` URL (antes do mapa ou após troca de bundle).
  private func dedupeLegacyExportedEvents(in exportCalendar: EKCalendar) {
    let cal = Calendar.current
    let start = cal.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    let end = cal.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: [exportCalendar])
    var bySlot: [String: [EKEvent]] = [:]
    for event in store.events(matching: predicate) {
      let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
      let minute = Int(event.startDate.timeIntervalSince1970 / 60)
      let key = "\(title)|\(minute)"
      bySlot[key, default: []].append(event)
    }

    var didChange = false
    for group in bySlot.values where group.count > 1 {
      let canonical = group.first(where: { $0.url != nil }) ?? group[0]
      for duplicate in group where duplicate.eventIdentifier != canonical.eventIdentifier {
        try? store.remove(duplicate, span: .thisEvent, commit: false)
        didChange = true
      }
    }
    if didChange { try? store.commit() }
  }

  private func stackedItemURL(prefix: String, itemId: String) -> String {
    prefix + itemId
  }

  /// Localiza eventos exportados pelo deep link `stacked://…` (sobrevive a troca de bundle / mapa perdido).
  private func findExportedEvents(itemId: String, urlPrefix: String) -> [EKEvent] {
    let targetURL = stackedItemURL(prefix: urlPrefix, itemId: itemId)
    if let batchExportedEventIndex, let cached = batchExportedEventIndex[targetURL] {
      return cached
    }
    let cal = Calendar.current
    let start = cal.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    let end = cal.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: store.calendars(for: .event))
    return store.events(matching: predicate).filter { $0.url?.absoluteString == targetURL }
  }

  /// Mantém um evento canônico e remove cópias órfãs (ex.: após mudar bundle identifier).
  private func reconcileDuplicateExports(
    itemId: String,
    urlPrefix: String,
    preferredCalendar: EKCalendar
  ) -> EKEvent? {
    let matches = findExportedEvents(itemId: itemId, urlPrefix: urlPrefix)
    guard !matches.isEmpty else { return nil }

    let preferredId = preferredCalendar.calendarIdentifier
    let canonical = matches.first(where: { $0.calendar.calendarIdentifier == preferredId })
      ?? matches.first!

    for duplicate in matches where duplicate.eventIdentifier != canonical.eventIdentifier {
      try? store.remove(duplicate, span: .thisEvent, commit: false)
    }
    try? store.commit()
    return canonical
  }

  private func findLegacyExportedEvent(title: String, start: Date, calendar: EKCalendar) -> EKEvent? {
    let cal = Calendar.current
    let dayStart = TaskMapper.startOfDay(start)
    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400)
    let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: [calendar])
    return store.events(matching: predicate).first { event in
      let eventTitle = event.title?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
      guard eventTitle == normalized else { return false }
      return abs(event.startDate.timeIntervalSince(start)) < 120
    }
  }

  private func saveExportedEvent(
    itemId: String,
    title: String,
    start: Date,
    end: Date,
    isAllDay: Bool,
    urlPrefix: String,
    map: [String: String],
    persistMap: ([String: String]) -> Void
  ) {
    guard let calendar = resolveExportCalendar() else { return }

    let event: EKEvent
    if let existingId = map[itemId], let existing = store.event(withIdentifier: existingId) {
      event = existing
    } else if let reconciled = reconcileDuplicateExports(
      itemId: itemId,
      urlPrefix: urlPrefix,
      preferredCalendar: calendar
    ) {
      event = reconciled
    } else if let legacy = findLegacyExportedEvent(
      title: title,
      start: start,
      calendar: calendar
    ) {
      event = legacy
    } else {
      event = EKEvent(eventStore: store)
    }

    event.title = title
    event.startDate = start
    event.endDate = end
    event.isAllDay = isAllDay
    event.calendar = calendar
    event.url = URL(string: stackedItemURL(prefix: urlPrefix, itemId: itemId))

    do {
      try store.save(event, span: .thisEvent, commit: true)
      guard let eventId = event.eventIdentifier else { return }
      if batchExportedEventIndex != nil {
        let url = stackedItemURL(prefix: urlPrefix, itemId: itemId)
        batchExportedEventIndex?[url] = [event]
      } else {
        _ = reconcileDuplicateExports(itemId: itemId, urlPrefix: urlPrefix, preferredCalendar: calendar)
      }
      var updated = map
      updated[itemId] = eventId
      persistMap(updated)
    } catch {
      cachedExportCalendar = nil
      UserDefaults.standard.removeObject(forKey: Self.exportCalendarIdKey)
    }
  }

  private func removeExportedEvent(
    itemId: String,
    map: [String: String],
    persistMap: ([String: String]) -> Void
  ) {
    guard let eventId = map[itemId],
          let event = store.event(withIdentifier: eventId) else {
      var updated = map
      updated.removeValue(forKey: itemId)
      persistMap(updated)
      return
    }
    do {
      try store.remove(event, span: .thisEvent, commit: true)
    } catch { }
    var updated = map
    updated.removeValue(forKey: itemId)
    persistMap(updated)
  }

  private func saveExportedReminder(
    itemId: String,
    title: String,
    dueDate: Date,
    time: String?,
    urlPrefix: String,
    map: [String: String],
    persistMap: ([String: String]) -> Void
  ) {
    guard let list = resolveExportReminderList() else { return }

    let reminder: EKReminder
    if let existingId = map[itemId],
       let existing = store.calendarItem(withIdentifier: existingId) as? EKReminder {
      reminder = existing
    } else {
      reminder = EKReminder(eventStore: store)
    }

    reminder.title = title
    reminder.calendar = list
    reminder.isCompleted = false
    reminder.dueDateComponents = dueDateComponents(dueDate: dueDate, time: time)
    reminder.url = URL(string: urlPrefix + itemId)

    do {
      try store.save(reminder, commit: true)
      let reminderId = reminder.calendarItemIdentifier
      guard !reminderId.isEmpty else { return }
      var updated = map
      updated[itemId] = reminderId
      persistMap(updated)
    } catch {
      cachedExportReminderList = nil
      UserDefaults.standard.removeObject(forKey: Self.exportReminderListIdKey)
    }
  }

  private func removeExportedReminder(
    itemId: String,
    map: [String: String],
    persistMap: ([String: String]) -> Void
  ) {
    guard let reminderId = map[itemId],
          let reminder = store.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      var updated = map
      updated.removeValue(forKey: itemId)
      persistMap(updated)
      return
    }
    do {
      try store.remove(reminder, commit: true)
    } catch { }
    var updated = map
    updated.removeValue(forKey: itemId)
    persistMap(updated)
  }

  private func mapEvent(_ event: EKEvent) -> CalendarEvent {
    let color: UInt32?
    if let cg = event.calendar.cgColor {
      let ui = UIColor(cgColor: cg)
      var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
      ui.getRed(&r, green: &g, blue: &b, alpha: &a)
      color = (UInt32(r * 255) << 16) | (UInt32(g * 255) << 8) | UInt32(b * 255)
    } else {
      color = nil
    }

    return CalendarEvent(
      id: event.eventIdentifier,
      title: event.title ?? "Sem título",
      startDate: event.startDate,
      endDate: event.endDate,
      isAllDay: event.isAllDay,
      calendarTitle: event.calendar.title,
      calendarColorHex: color
    )
  }

  private func notifyStoresToRefresh() async {
    await TaskStore.shared.reloadCalendarEvents()
    await UpcomingStore.shared.reloadCalendarEvents()
  }
}
