import Foundation
import Supabase

@MainActor
@Observable
final class HomeStore {
  static let shared = HomeStore()

  private(set) var overdueCount = 0
  private(set) var todayPending = 0
  private(set) var todayDone = 0
  private(set) var todayTotal = 0
  private(set) var inboxCount = 0
  private(set) var upcomingCount = 0
  private(set) var projects: [HomeProject] = []
  private(set) var isLoading = false
  private(set) var error: String?
  private(set) var focusTaskTitle: String?
  private(set) var focusTaskTime: String?
  private(set) var primaryOverdueTitle: String?
  private(set) var primaryOverdueTime: String?
  private(set) var queueLines: [HomeHeroInsights.QueueLine] = []
  private(set) var completionStreak = 0
  private(set) var streakWeekCompleted: [Bool] = Array(repeating: false, count: 7)
  private(set) var weatherSnapshot: HomeHeroInsights.WeatherSnapshot = HomeHeroInsights.placeholderWeather(for: .current)

  private init() {}

  var motivationContent: (quote: String, footnote: String) {
    HomeMotivationQuotes.forToday()
  }

  var firstName: String {
    displayNameComponents.first ?? ""
  }

  var avatarURL: URL? {
    guard let user = SupabaseService.client.auth.currentUser else { return nil }
    let raw = metadataString(user.userMetadata["avatar_url"])
    guard raw.hasPrefix("http"), let url = URL(string: raw) else { return nil }
    return url
  }

  var avatarInitials: String {
    let meta = SupabaseService.client.auth.currentUser?.userMetadata ?? [:]
    let display = metadataString(meta["apelido"]).nilIfEmpty
      ?? metadataString(meta["nome"]).nilIfEmpty
      ?? firstName
    let parts = display.split(separator: " ")
    if parts.count >= 2 {
      return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
    }
    return String(display.prefix(2)).uppercased()
  }

  private var displayNameComponents: [String] {
    guard let user = SupabaseService.client.auth.currentUser else { return [] }
    let meta = user.userMetadata
    let apelido = metadataString(meta["apelido"])
    if !apelido.isEmpty { return apelido.split(separator: " ").map(String.init) }
    let nome = metadataString(meta["nome"])
    if !nome.isEmpty { return nome.split(separator: " ").map(String.init) }
    let email = user.email ?? ""
    guard !email.isEmpty else { return [] }
    let local = email.split(separator: "@").first.map(String.init) ?? email
    let part = local.split(separator: ".").first.map(String.init) ?? local
    guard let first = part.first else { return [local] }
    return [first.uppercased() + part.dropFirst()]
  }

  private func metadataString(_ value: AnyJSON?) -> String {
    guard let value else { return "" }
    if let s = value.stringValue { return s.trimmingCharacters(in: .whitespacesAndNewlines) }
    return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var greetingPhrase: String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 { return "Bom dia," }
    if hour < 18 { return "Boa tarde," }
    return "Boa noite,"
  }

  var timeOfDay: HomeTimeOfDay { .current }

  var greeting: String {
    let base = greetingPhrase.dropLast() // "Bom dia," → "Bom dia"
    let name = firstName
    return name.isEmpty ? String(base) : "\(base), \(name)"
  }

  func statusLabel(overdueCount: Int) -> String {
    if overdueCount == 1 { return "1 pendência atrasada" }
    if overdueCount > 1 { return "\(overdueCount) pendências atrasadas" }
    return "Tudo em dia"
  }

  func focusHeroTitle(overdueCount: Int) -> String {
    overdueCount > 0 ? "Você tem pendências" : "Tudo certo!"
  }

  func focusHeroSubtitle(overdueCount: Int) -> String {
    if overdueCount == 1 { return "1 pendência atrasada precisa da sua atenção." }
    if overdueCount > 1 { return "\(overdueCount) pendências atrasadas precisam da sua atenção." }
    return "Você está em dia com tudo."
  }

  func overdueChipLabel(overdueCount: Int) -> String {
    if overdueCount == 1 { return "1 atrasada" }
    return "\(overdueCount) atrasadas"
  }

  var panelPrimaryTitle: String {
    if overdueCount > 0 {
      return primaryOverdueTitle ?? statusLabel(overdueCount: overdueCount)
    }
    return focusTaskTitle ?? "Nada pendente para hoje"
  }

  var panelPrimaryTime: String? {
    overdueCount > 0 ? primaryOverdueTime : focusTaskTime
  }

  var nextStepTitle: String {
    if overdueCount > 0 {
      return primaryOverdueTitle ?? statusLabel(overdueCount: overdueCount)
    }
    return focusTaskTitle ?? "Nada pendente para hoje"
  }

  var completedDaysThisWeek: Int {
    streakWeekCompleted.filter { $0 }.count
  }

  var formattedLongDate: String {
    HomeHeroInsights.formattedLongDate()
  }

  var todayProgressPercent: Int {
    guard todayTotal > 0 else { return todayPending == 0 && overdueCount == 0 ? 100 : 0 }
    return Int((Double(todayDone) / Double(todayTotal) * 100).rounded())
  }

  var greetingProgressSubtitle: String {
    if overdueCount > 0 { return "Algumas pendências precisam de atenção." }
    if todayTotal == 0 { return "Nenhuma tarefa agendada para hoje." }
    if todayDone == todayTotal { return "Tudo em dia! Continue assim." }
    return "Você está avançando no dia."
  }

  var greetingFocusSubtitle: String {
    "Foco é fazer o importante acontecer."
  }

  var greetingFocusCardTitle: String {
    focusTaskTitle ?? "Avançar no que importa."
  }

  func load() async {
    isLoading = projects.isEmpty
    error = nil
    defer { isLoading = false }
    guard let userId = SupabaseService.client.auth.currentUser?.id else {
      error = "Sessão inválida. Faça login novamente."
      return
    }
    let today = TaskMapper.dateString(Date())
    do {
      async let summaryReq = TaskRepository.shared.fetchHomeTaskSummary(userId: userId, todayStr: today)
      async let projectsReq = ProjectRepository.shared.fetchHomeProjects()
      async let upcomingReq = TaskRepository.shared.countUpcomingTasks(userId: userId, todayStr: today)
      async let pendingReq = TaskRepository.shared.fetchPendingTaskProjectIds(userId: userId)

      let summary = try await summaryReq
      overdueCount = summary.overdueCount
      todayPending = summary.todayPending
      todayDone = summary.todayDone
      todayTotal = summary.todayTotal
      projects = try await projectsReq
      upcomingCount = try await upcomingReq
      inboxCount = try await pendingReq.filter { $0 == nil }.count
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      self.error = error.localizedDescription
    }
    await refreshHeroInsights(todayStr: today)
  }

  /// Atualiza badges da Home sem spinner — usado após mutações em outras abas.
  func refreshCounts() async {
    guard let userId = SupabaseService.client.auth.currentUser?.id else { return }
    let today = TaskMapper.dateString(Date())
    do {
      async let summaryReq = TaskRepository.shared.fetchHomeTaskSummary(userId: userId, todayStr: today)
      async let projectsReq = ProjectRepository.shared.fetchHomeProjects()
      async let upcomingReq = TaskRepository.shared.countUpcomingTasks(userId: userId, todayStr: today)
      async let pendingReq = TaskRepository.shared.fetchPendingTaskProjectIds(userId: userId)
      async let heroInsightsReq = refreshHeroInsights(todayStr: today)

      let summary = try await summaryReq
      overdueCount = summary.overdueCount
      todayPending = summary.todayPending
      todayDone = summary.todayDone
      todayTotal = summary.todayTotal
      projects = try await projectsReq
      upcomingCount = try await upcomingReq
      inboxCount = try await pendingReq.filter { $0 == nil }.count
      _ = await heroInsightsReq
    } catch {
      if AsyncLoad.isCancellation(error) { return }
    }
  }

  private func refreshHeroInsights(todayStr: String) async {
    let cal = Calendar.current
    let today = TaskMapper.parseDueDate(todayStr) ?? cal.startOfDay(for: Date())
    let streakSince = cal.date(byAdding: .day, value: -21, to: today) ?? today

    async let todayTasksReq = TaskRepository.shared.fetchTodayTasks()
    async let completionsReq = TaskRepository.shared.fetchProductivityCompletionDates(since: streakSince)

    let todayTasks = (try? await todayTasksReq) ?? []
    let completions = (try? await completionsReq) ?? []

    if let focus = HomeHeroInsights.resolveFocusTask(from: todayTasks) {
      focusTaskTitle = focus.title
      focusTaskTime = focus.time
    } else {
      focusTaskTitle = nil
      focusTaskTime = nil
    }

    if let overdue = HomeHeroInsights.resolvePrimaryOverdue(from: todayTasks) {
      primaryOverdueTitle = overdue.title
      primaryOverdueTime = overdue.time
    } else {
      primaryOverdueTitle = nil
      primaryOverdueTime = nil
    }

    queueLines = HomeHeroInsights.resolveQueueLines(from: todayTasks)

    let streak = HomeHeroInsights.streak(from: completions)
    completionStreak = streak.days
    streakWeekCompleted = streak.weekCompleted

    weatherSnapshot = await HomeWeatherService.shared.snapshot(fallbackTimeOfDay: timeOfDay)
  }
}

private extension String {
  var nilIfEmpty: String? {
    let t = trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
  }
}

@MainActor
@Observable
final class ProjectDetailStore {
  let projectId: String
  let projectName: String

  private(set) var sections: [ProjectSection] = []
  private(set) var pending: [Task] = []
  private(set) var completed: [Task] = []
  private(set) var isLoading = true
  private(set) var error: String?

  init(projectId: String, projectName: String, initialSnapshot: ProjectDetailSnapshot? = nil) {
    self.projectId = projectId
    self.projectName = projectName
    if let snap = initialSnapshot {
      sections = snap.sections
      pending = snap.pending
      completed = snap.completed
      isLoading = false
    }
  }

  func adoptSnapshot(_ snapshot: ProjectDetailSnapshot) {
    sections = snapshot.sections
    pending = snapshot.pending
    completed = snapshot.completed
    isLoading = snapshot.pending.isEmpty && snapshot.completed.isEmpty
    error = nil
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &pending)
    SubtaskListPatch.apply(snapshot, to: &completed)
  }

  func load() async {
    let hadData = !pending.isEmpty || !completed.isEmpty
    if !hadData { isLoading = true }
    error = nil
    do {
      async let sectionsReq = SectionRepository.shared.fetchSections(projectId: projectId)
      async let pendingReq = TaskRepository.shared.fetchTasksByProject(projectId)
      async let completedReq = TaskRepository.shared.fetchCompletedTasksByProject(projectId)
      let newSections = try await sectionsReq
      let newPending = try await pendingReq
      let newCompleted = try await completedReq

      if newSections == sections, newPending == pending, newCompleted == completed {
        isLoading = false
        return
      }

      let apply = {
        self.sections = newSections
        self.pending = newPending
        self.completed = newCompleted
        ProjectDetailCache.shared.store(
          projectId: self.projectId,
          sections: newSections,
          pending: newPending,
          completed: newCompleted
        )
      }

      if hadData {
        await NavigationPushMotion.afterSettle(apply)
      } else {
        apply()
      }
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  func tasks(in sectionId: String?) -> [Task] {
    pending.filter { $0.sectionId == sectionId }
  }

  func complete(_ task: Task) {
    guard let i = pending.firstIndex(where: { $0.id == task.id }) else { return }
    guard !pending[i].done else { return }

    let originalIndex = i
    let snapshot = pending[i]
    let taskId = task.id

    pending[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        guard let idx = pending.firstIndex(where: { $0.id == taskId }) else { return }
        var updated = pending[idx]
        updated.done = true
        pending.remove(at: idx)
        completed.insert(updated, at: 0)
      },
      persist: {
        if let newId = try await TaskRepository.shared.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
          await self.load()
        }
        GlobalDataRefresh.afterTaskMutation()
      },
      rollback: { [self] in
        completed.removeAll { $0.id == taskId }
        var restored = snapshot
        restored.done = false
        pending.insert(restored, at: min(originalIndex, pending.count))
      }
    )
  }

  func delete(_ task: Task) {
    pending.removeAll { $0.id == task.id }
    completed.removeAll { $0.id == task.id }
    _Concurrency.Task {
      try? await TaskRepository.shared.deleteTask(id: task.id)
      GlobalDataRefresh.afterTaskMutation()
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await TaskRepository.shared.updateTaskDate(id: task.id, isoDate: iso)
    pending.removeAll { $0.id == task.id }
    await load()
  }

  func duplicate(_ task: Task) {
    _Concurrency.Task {
      _ = try? await TaskRepository.shared.duplicateTask(task)
      await load()
    }
  }

  func uncomplete(_ task: Task) {
    guard let i = completed.firstIndex(where: { $0.id == task.id }) else { return }

    let originalIndex = i
    let snapshot = completed[i]
    let taskId = task.id

    completed.remove(at: i)
    var restored = snapshot
    restored.done = false
    pending.insert(restored, at: 0)
    HapticService.light()

    _Concurrency.Task {
      do {
        try await TaskRepository.shared.toggleTaskDone(id: taskId, done: false)
      } catch {
        pending.removeAll { $0.id == taskId }
        completed.insert(snapshot, at: min(originalIndex, completed.count))
      }
    }
  }

  func createSection(name: String) async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    try? await SectionRepository.shared.createSection(projectId: projectId, name: trimmed)
    await load()
  }

  func renameSection(_ section: ProjectSection, name: String) async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    try? await SectionRepository.shared.renameSection(id: section.id, name: trimmed)
    await load()
  }

  func deleteSection(_ section: ProjectSection) async {
    try? await SectionRepository.shared.deleteSection(id: section.id)
    await load()
  }

  func moveTasks(in sectionId: String?, from source: IndexSet, to destination: Int) {
    var bucket = tasks(in: sectionId)
    guard !bucket.isEmpty else { return }
    bucket.move(fromOffsets: source, toOffset: destination)
    pending = orderedPending(sectionId: sectionId, reordered: bucket)
    syncCache()

    let updates = bucket.enumerated().map { (id: $1.id, order: $0) }
    _Concurrency.Task {
      do {
        try await TaskRepository.shared.updateTaskOrders(updates)
        HapticService.selection()
      } catch {
        await load()
      }
    }
  }

  private func orderedPending(sectionId: String?, reordered: [Task]) -> [Task] {
    var result: [Task] = []
    for section in sections {
      if section.id == sectionId {
        result.append(contentsOf: reordered)
      } else {
        result.append(contentsOf: pending.filter { $0.sectionId == section.id })
      }
    }
    if sectionId == nil {
      result.append(contentsOf: reordered)
    } else {
      result.append(contentsOf: pending.filter { $0.sectionId == nil })
    }
    return result
  }

  private func syncCache() {
    ProjectDetailCache.shared.store(
      projectId: projectId,
      sections: sections,
      pending: pending,
      completed: completed
    )
  }
}
