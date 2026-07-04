import EventKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class EventKitCalendarService {
  static let shared = EventKitCalendarService()

  static let stackedCalendarTitle = "Stacked"
  static let stackedTaskURLPrefix = "stacked://task/"

  private let store = EKEventStore()
  private static let eventMapKey = "calendar_task_event_map"

  private(set) var authorizationGranted = false
  private(set) var writableCalendars: [EKCalendar] = []
  private(set) var importableCalendars: [EKCalendar] = []

  private var eventMap: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: Self.eventMapKey) as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: Self.eventMapKey) }
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
        self.reloadCalendarLists()
        await self.notifyStoresToRefresh()
      }
    }
  }

  func refreshAuthorizationState() {
    let status = EKEventStore.authorizationStatus(for: .event)
    authorizationGranted = hasReadAccess(status)
    reloadCalendarLists()
  }

  func requestAccess() async -> Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if hasReadAccess(status) {
      authorizationGranted = true
      reloadCalendarLists()
      return true
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
      authorizationGranted = hasReadAccess(EKEventStore.authorizationStatus(for: .event)) || granted
      reloadCalendarLists()
      return authorizationGranted
    } catch {
      authorizationGranted = hasReadAccess(EKEventStore.authorizationStatus(for: .event))
      reloadCalendarLists()
      return authorizationGranted
    }
  }

  func reloadCalendarLists() {
    guard authorizationGranted else {
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
    guard CalendarPreferences.exportEnabled, authorizationGranted else { return }

    if task.done || task.dueDate == nil || task.time == nil || task.time?.isEmpty == true {
      removeEvent(forTaskId: task.id)
      return
    }

    guard let due = task.dueDate,
          let time = task.time,
          let start = TaskMapper.combinedDateTime(dueDate: due, time: time) else {
      removeEvent(forTaskId: task.id)
      return
    }

    let end = start.addingTimeInterval(3600)
    let calendar = stackedExportCalendar()

    let event: EKEvent
    if let existingId = eventMap[task.id], let existing = store.event(withIdentifier: existingId) {
      event = existing
    } else {
      event = EKEvent(eventStore: store)
    }

    event.title = task.title
    event.startDate = start
    event.endDate = end
    event.calendar = calendar
    event.url = URL(string: Self.stackedTaskURLPrefix + task.id)

    do {
      try store.save(event, span: .thisEvent, commit: true)
      var map = eventMap
      map[task.id] = event.eventIdentifier
      eventMap = map
    } catch {
      // Falha silenciosa — usuário pode ter revogado permissão.
    }
  }

  func removeEvent(forTaskId taskId: String) {
    guard let eventId = eventMap[taskId],
          let event = store.event(withIdentifier: eventId) else {
      var map = eventMap
      map.removeValue(forKey: taskId)
      eventMap = map
      return
    }
    do {
      try store.remove(event, span: .thisEvent, commit: true)
    } catch { }
    var map = eventMap
    map.removeValue(forKey: taskId)
    eventMap = map
  }

  func syncAllExportableTasks() async {
    guard CalendarPreferences.exportEnabled else { return }
    do {
      let tasks = try await TaskRepository.shared.fetchDatedPendingTasks()
      for task in tasks where !task.done {
        syncTask(task)
      }
    } catch { }
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
    return status == .authorized
  }

  private func selectedImportCalendars() -> [EKCalendar] {
    let selected = CalendarPreferences.selectedCalendarIDs
    let stackedId = stackedExportCalendar().calendarIdentifier
    if selected.isEmpty {
      return importableCalendars.filter { $0.calendarIdentifier != stackedId }
    }
    return importableCalendars.filter { selected.contains($0.calendarIdentifier) && $0.calendarIdentifier != stackedId }
  }

  private func stackedExportCalendar() -> EKCalendar {
    if let existing = store.calendars(for: .event).first(where: { $0.title == Self.stackedCalendarTitle }) {
      return existing
    }

    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.title = Self.stackedCalendarTitle
    calendar.cgColor = UIColor(Color(hex: 0x5FD3DC)).cgColor

    if let source = store.defaultCalendarForNewEvents?.source
      ?? store.sources.first(where: { $0.sourceType == .local })
      ?? store.sources.first {
      calendar.source = source
    }

    try? store.saveCalendar(calendar, commit: true)
    return calendar
  }

  private func isStackedExportedEvent(_ event: EKEvent) -> Bool {
    if event.calendar.title == Self.stackedCalendarTitle { return true }
    if let url = event.url?.absoluteString, url.hasPrefix(Self.stackedTaskURLPrefix) { return true }
    return false
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
