import Foundation
import Supabase

// Paridade lib/services/task_repository.dart
@MainActor
final class TaskRepository {
  static let shared = TaskRepository()

  private var client: SupabaseClient { SupabaseService.client }

  private init() {}

  func fetchTodayTasks() async throws -> [Task] {
    let today = TaskMapper.dateString(Date())
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: false)
      .lte("data_vencimento", value: today)
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchCompletedTodayTasks() async throws -> [Task] {
    let bounds = TaskMapper.completionDayBounds()
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: true)
      .gte("data_conclusao", value: bounds.start)
      .lt("data_conclusao", value: bounds.end)
      .order("data_conclusao", ascending: false)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  /// Timestamps de conclusão de tarefas desde uma data (relatório de produtividade).
  func fetchProductivityCompletionDates(since: Date) async throws -> [Date] {
    struct Row: Decodable { let data_conclusao: String? }
    let rows: [Row] = try await client
      .from("tasks")
      .select("data_conclusao")
      .eq("concluida", value: true)
      .not("data_conclusao", operator: .is, value: "null")
      .gte("data_conclusao", value: TaskMapper.isoTimestamp(since))
      .order("data_conclusao", ascending: false)
      .execute()
      .value
    return rows.compactMap { TaskMapper.parseCompletionTimestamp($0.data_conclusao) }
  }

  func countAllCompletedTasks() async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let rows: [IdRow] = try await client
      .from("tasks")
      .select("id")
      .eq("concluida", value: true)
      .execute()
      .value
    return rows.count
  }

  func fetchInboxTasks() async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: false)
      .is("data_vencimento", value: nil)
      .is("project_id", value: nil)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchCompletedInboxTasks() async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: true)
      .is("data_vencimento", value: nil)
      .is("project_id", value: nil)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchTaskById(_ id: String) async throws -> Task? {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("id", value: id)
      .limit(1)
      .execute()
      .value
    return TaskMapper.mapList(rows).first
  }

  func toggleTaskDone(id: String, done: Bool) async throws {
    struct Payload: Encodable {
      let concluida: Bool
      let data_conclusao: String?
    }
    let payload = Payload(
      concluida: done,
      data_conclusao: done ? TaskMapper.isoTimestamp(Date()) : nil
    )
    try await client
      .from("tasks")
      .update(payload)
      .eq("id", value: id)
      .execute()
    if done {
      await NotificationService.shared.cancelTaskNotification(id: id)
    } else if let task = try await fetchTaskById(id) {
      await NotificationService.shared.syncTaskNotification(task: task)
    }
  }

  /// Marca concluída e cria próxima ocorrência quando aplicável.
  /// Retorna o id da nova tarefa, se criada.
  func completeTask(_ task: Task) async throws -> String? {
    try await toggleTaskDone(id: task.id, done: true)
    return try await createNextOccurrence(for: task)
  }

  func createNextOccurrence(for task: Task) async throws -> String? {
    guard let recurrence = task.recurrence, !recurrence.isEmpty,
          let due = task.dueDate,
          let nextDate = RecurrenceCodec.nextDate(from: due, json: recurrence)
    else { return nil }

    guard let userId = client.auth.currentUser?.id else {
      throw NSError(domain: "Stacked", code: 401, userInfo: [NSLocalizedDescriptionKey: "Não autenticado"])
    }

    struct OrdRow: Decodable { let ordem: Int? }
    let ordRow: OrdRow? = try? await client
      .from("tasks")
      .select("ordem")
      .eq("id", value: task.id)
      .single()
      .execute()
      .value
    let ordem = ordRow?.ordem

    struct IdRow: Decodable { let id: String }
    let row: IdRow = try await client.from("tasks").insert(
      NextOccurrenceInsertPayload(
        titulo: task.title,
        descricao: task.description,
        prioridade: task.priority?.rawValue,
        project_id: task.projectId,
        section_id: task.sectionId,
        data_vencimento: TaskMapper.dateString(nextDate),
        hora: task.time,
        user_id: userId,
        concluida: false,
        recorrencia: recurrence,
        whatsapp_rotina: task.whatsappRoutine,
        ordem: ordem
      )
    ).select("id").single().execute().value

    if !task.labels.isEmpty {
      let links = task.labels.map { ["task_id": row.id, "label_id": $0.id] }
      try await client.from("task_labels").insert(links).execute()
    }

    if let time = task.time, !time.isEmpty {
      await NotificationService.shared.syncTaskNotification(
        id: row.id,
        title: task.title,
        dueDate: nextDate,
        time: time
      )
    }

    return row.id
  }

  func updateTaskDate(id: String, isoDate: String) async throws {
    try await client
      .from("tasks")
      .update(["data_vencimento": isoDate])
      .eq("id", value: id)
      .execute()
    if let task = try await fetchTaskById(id) {
      await NotificationService.shared.syncTaskNotification(task: task)
    }
  }

  func deleteTask(id: String) async throws {
    await NotificationService.shared.cancelTaskNotification(id: id)
    try await client
      .from("tasks")
      .delete()
      .eq("id", value: id)
      .execute()
  }

  // MARK: - Home aggregates (paridade task_repository.dart)

  func fetchHomeTaskSummary(userId: UUID, todayStr: String) async throws -> HomeTaskSummary {
    struct IdRow: Decodable { let id: String }

    async let todayRows: [TaskRowDTO] = client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("user_id", value: userId)
      .eq("data_vencimento", value: todayStr)
      .execute()
      .value

    async let overdueRows: [IdRow] = client
      .from("tasks")
      .select("id")
      .eq("user_id", value: userId)
      .eq("concluida", value: false)
      .lt("data_vencimento", value: todayStr)
      .execute()
      .value

    async let overdueSubtasksReq = SubtaskRepository.shared.countOverdueScheduleEntries(todayStr: todayStr)
    async let todaySubtasksPendingReq = SubtaskRepository.shared.countDueTodayPending(todayStr: todayStr)

    let today = try await todayRows
    let overdue = try await overdueRows
    let overdueSubtasks = try await overdueSubtasksReq
    let todaySubtasksPending = try await todaySubtasksPendingReq
    let mapped = TaskMapper.mapList(today)
    let taskTodayPending = mapped.filter { !$0.done }.count
    return HomeTaskSummary(
      todayTotal: mapped.count,
      todayDone: mapped.filter(\.done).count,
      todayPending: taskTodayPending + todaySubtasksPending,
      overdueCount: overdue.count + overdueSubtasks
    )
  }

  func fetchPendingTaskProjectIds(userId: UUID) async throws -> [String?] {
    struct Row: Decodable { let project_id: String? }
    let rows: [Row] = try await client
      .from("tasks")
      .select("project_id")
      .eq("user_id", value: userId)
      .eq("concluida", value: false)
      .execute()
      .value
    return rows.map(\.project_id)
  }

  func countUpcomingTasks(userId: UUID, todayStr: String) async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let rows: [IdRow] = try await client
      .from("tasks")
      .select("id")
      .eq("user_id", value: userId)
      .eq("concluida", value: false)
      .gt("data_vencimento", value: todayStr)
      .execute()
      .value
    return rows.count
  }

  func fetchTasksByProject(_ projectId: String) async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("project_id", value: projectId)
      .eq("concluida", value: false)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchCompletedTasksByProject(_ projectId: String) async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("project_id", value: projectId)
      .eq("concluida", value: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  // MARK: - Em breve (paridade upcoming_screen.dart)

  func fetchDatedPendingTasks() async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: false)
      .not("data_vencimento", operator: .is, value: "null")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  // MARK: - Filtros (paridade task_repository.dart)

  func fetchFilterDashboardCounts(todayStr: String, weekStr: String) async throws -> FilterDashboardCounts {
    struct IdRow: Decodable { let id: String }

    async let overdueReq: [IdRow] = client
      .from("tasks")
      .select("id")
      .eq("concluida", value: false)
      .lt("data_vencimento", value: todayStr)
      .execute()
      .value

    async let todayReq: [IdRow] = client
      .from("tasks")
      .select("id")
      .eq("concluida", value: false)
      .eq("data_vencimento", value: todayStr)
      .execute()
      .value

    async let weekReq: [IdRow] = client
      .from("tasks")
      .select("id")
      .eq("concluida", value: false)
      .gt("data_vencimento", value: todayStr)
      .lte("data_vencimento", value: weekStr)
      .execute()
      .value

    async let completedReq: [IdRow] = {
      let bounds = TaskMapper.completionDayBounds(
        for: TaskMapper.parseDueDate(todayStr) ?? Date()
      )
      return try await client
        .from("tasks")
        .select("id")
        .eq("concluida", value: true)
        .gte("data_conclusao", value: bounds.start)
        .lt("data_conclusao", value: bounds.end)
        .execute()
        .value
    }()

    async let overdueSubReq = SubtaskRepository.shared.countOverdueScheduleEntries(todayStr: todayStr)
    async let todaySubReq = SubtaskRepository.shared.countDueTodayPending(todayStr: todayStr)
    async let weekSubReq = SubtaskRepository.shared.countDueInWeekPending(todayStr: todayStr, weekStr: weekStr)

    let (overdue, today, week, completed) = try await (overdueReq, todayReq, weekReq, completedReq)
    let (overdueSub, todaySub, weekSub) = try await (overdueSubReq, todaySubReq, weekSubReq)
    return FilterDashboardCounts(
      overdue: overdue.count + overdueSub,
      today: today.count + todaySub,
      week: week.count + weekSub,
      completedToday: completed.count
    )
  }

  func fetchFilteredTasks(kind: TaskFilterKind, todayStr: String, weekStr: String) async throws -> [Task] {
    var query = client.from("tasks").select(TaskSelect.unified)

    switch kind {
    case .overdue:
      query = query.eq("concluida", value: false).lt("data_vencimento", value: todayStr)
    case .today:
      query = query.eq("concluida", value: false).eq("data_vencimento", value: todayStr)
    case .week:
      query = query
        .eq("concluida", value: false)
        .gt("data_vencimento", value: todayStr)
        .lte("data_vencimento", value: weekStr)
    case .completedToday:
      let bounds = TaskMapper.completionDayBounds(
        for: TaskMapper.parseDueDate(todayStr) ?? Date()
      )
      query = query
        .eq("concluida", value: true)
        .gte("data_conclusao", value: bounds.start)
        .lt("data_conclusao", value: bounds.end)
    }

    let rows: [TaskRowDTO] = try await query
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchPresetFilterResults(
    kind: TaskFilterKind,
    todayStr: String,
    weekStr: String
  ) async throws -> [FilterResultItem] {
    switch kind {
    case .completedToday:
      let tasks = try await fetchFilteredTasks(kind: kind, todayStr: todayStr, weekStr: weekStr)
      return tasks.map { .task($0) }
    case .overdue:
      async let todayTasksReq = fetchTodayTasks()
      async let subtasksReq = fetchPresetSubtaskEntries(kind: kind, todayStr: todayStr, weekStr: weekStr)
      let todayTasks = try await todayTasksReq
      let subtaskEntries = try await subtasksReq
      let tasks = TaskMapper.splitTodayPending(todayTasks).overdue
      return buildPresetFilterResults(
        tasks: tasks,
        subtaskEntries: subtaskEntries,
        dateScope: .overdue,
        todayStr: todayStr,
        weekStr: weekStr
      )
    case .today:
      async let todayTasksReq = fetchTodayTasks()
      async let subtasksReq = fetchPresetSubtaskEntries(kind: kind, todayStr: todayStr, weekStr: weekStr)
      let todayTasks = try await todayTasksReq
      let subtaskEntries = try await subtasksReq
      let tasks = TaskMapper.splitTodayPending(todayTasks).today
      return buildPresetFilterResults(
        tasks: tasks,
        subtaskEntries: subtaskEntries,
        dateScope: .today,
        todayStr: todayStr,
        weekStr: weekStr
      )
    case .week:
      guard let dateScope = kind.presetDateScope else { return [] }
      async let tasksReq = fetchFilteredTasks(kind: kind, todayStr: todayStr, weekStr: weekStr)
      async let subtasksReq = fetchPresetSubtaskEntries(kind: kind, todayStr: todayStr, weekStr: weekStr)
      let tasks = try await tasksReq
      let subtaskEntries = try await subtasksReq
      return buildPresetFilterResults(
        tasks: tasks,
        subtaskEntries: subtaskEntries,
        dateScope: dateScope,
        todayStr: todayStr,
        weekStr: weekStr
      )
    }
  }

  private func fetchPresetSubtaskEntries(
    kind: TaskFilterKind,
    todayStr: String,
    weekStr: String
  ) async throws -> [SubtaskScheduleEntry] {
    switch kind {
    case .overdue:
      return try await SubtaskRepository.shared.fetchOverdueScheduleEntries(todayStr: todayStr)
    case .today:
      return try await SubtaskRepository.shared.fetchTodayOnlyScheduleEntries(todayStr: todayStr)
    case .week:
      return try await SubtaskRepository.shared.fetchWeekScheduleEntries(todayStr: todayStr, weekStr: weekStr)
    case .completedToday:
      return []
    }
  }

  private func buildPresetFilterResults(
    tasks: [Task],
    subtaskEntries: [SubtaskScheduleEntry],
    dateScope: FilterDateScope,
    todayStr: String,
    weekStr: String
  ) -> [FilterResultItem] {
    let criteria = FilterCriteria(labelIds: [], priorities: [], projectId: nil, dateScope: dateScope)
    let matchingTaskIds = Set(tasks.map(\.id))
    var results: [FilterResultItem] = tasks.map { .task($0) }

    for entry in subtaskEntries where !entry.subtask.done {
      guard !matchingTaskIds.contains(entry.parent.id) else { continue }
      // scheduleParentSelect não embute subtasks — usar entry.subtask direto.
      let sub = entry.subtask
      let index = entry.parent.subtasks.firstIndex(where: { $0.id == sub.id }) ?? sub.order
      guard FilterMatcher.subtaskMatches(
        sub,
        parent: entry.parent,
        criteria: criteria,
        todayStr: todayStr,
        weekStr: weekStr
      ) else { continue }
      results.append(.subtask(sub, parent: entry.parent, index: index))
    }

    return results.sorted { presetResultSortDate($0) < presetResultSortDate($1) }
  }

  private func presetResultSortDate(_ item: FilterResultItem) -> Date {
    switch item {
    case .task(let task):
      return task.dueDate ?? .distantFuture
    case .subtask(let sub, _, _):
      return sub.dueDate ?? .distantFuture
    }
  }

  func fetchFilterResults(
    _ criteria: FilterCriteria,
    todayStr: String,
    weekStr: String
  ) async throws -> (pending: [FilterResultItem], completed: [FilterResultItem]) {
    let tasks = try await fetchTasksForFilterMatching(criteria)
    return (
      FilterMatcher.buildPendingResults(tasks: tasks, criteria: criteria, todayStr: todayStr, weekStr: weekStr),
      FilterMatcher.buildCompletedResults(tasks: tasks, criteria: criteria, todayStr: todayStr, weekStr: weekStr)
    )
  }

  private func fetchTasksForFilterMatching(_ criteria: FilterCriteria) async throws -> [Task] {
    var query = client.from("tasks").select(TaskSelect.unified)
    if let projectId = criteria.projectId {
      query = query.eq("project_id", value: projectId)
    }
    let rows: [TaskRowDTO] = try await query
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func fetchTasksMatchingCriteria(
    _ criteria: FilterCriteria,
    includeCompleted: Bool,
    todayStr: String,
    weekStr: String
  ) async throws -> [Task] {
    let split = try await fetchFilterResults(criteria, todayStr: todayStr, weekStr: weekStr)
    let items = includeCompleted ? split.pending + split.completed : split.pending
    return items.compactMap { item in
      if case .task(let task) = item { return task }
      return nil
    }
  }

  func fetchPendingAndCompletedMatchingCriteria(
    _ criteria: FilterCriteria,
    todayStr: String,
    weekStr: String
  ) async throws -> (pending: [FilterResultItem], completed: [FilterResultItem]) {
    try await fetchFilterResults(criteria, todayStr: todayStr, weekStr: weekStr)
  }

  func fetchAllPendingTasks() async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: false)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  /// Busca global — projeção leve, limitada para abertura rápida do sheet.
  func fetchPendingTasksForSearch(limit: Int = 400) async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.search)
      .eq("concluida", value: false)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .limit(limit)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  // MARK: - Create / duplicate / logbook

  struct CreateTaskInput {
    var title: String
    var description: String?
    var priority: Priority?
    var projectId: String?
    var sectionId: String?
    var dueDateISO: String?
    var time: String?
    var labelIds: [String] = []
  }

  func createTask(_ input: CreateTaskInput) async throws -> String {
    guard let userId = client.auth.currentUser?.id else {
      throw NSError(domain: "Stacked", code: 401, userInfo: [NSLocalizedDescriptionKey: "Não autenticado"])
    }
    struct IdRow: Decodable { let id: String }
    let row: IdRow = try await client.from("tasks").insert(
      CreateTaskInsertPayload(
        titulo: input.title,
        descricao: input.description,
        prioridade: input.priority?.rawValue,
        project_id: input.projectId,
        section_id: input.sectionId,
        data_vencimento: input.dueDateISO,
        hora: input.time,
        user_id: userId,
        concluida: false
      )
    ).select("id").single().execute().value

    if !input.labelIds.isEmpty {
      let links = input.labelIds.map { ["task_id": row.id, "label_id": $0] }
      try await client.from("task_labels").insert(links).execute()
    }
    if let dueISO = input.dueDateISO,
       let due = TaskMapper.parseDueDate(dueISO),
       let time = input.time,
       !time.isEmpty {
      await NotificationService.shared.syncTaskNotification(
        id: row.id,
        title: input.title,
        dueDate: due,
        time: time
      )
    }
    return row.id
  }

  func duplicateTask(_ task: Task) async throws -> String {
    let iso: String? = task.dueDate.map { TaskMapper.dateString($0) }
    return try await createTask(CreateTaskInput(
      title: "\(task.title) (cópia)",
      description: task.description,
      priority: task.priority,
      projectId: task.projectId,
      sectionId: task.sectionId,
      dueDateISO: iso,
      time: task.time,
      labelIds: task.labels.map(\.id)
    ))
  }

  func fetchLogbookTasks(limit: Int = 200) async throws -> [Task] {
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: true)
      .order("data_vencimento", ascending: false)
      .order("ordem", ascending: false)
      .limit(limit)
      .execute()
      .value
    return TaskMapper.mapList(rows)
  }

  func updateTaskProject(id: String, projectId: String?, sectionId: String?) async throws {
    struct Payload: Encodable {
      let project_id: String?
      let section_id: String?
    }
    try await client.from("tasks").update(
      Payload(project_id: projectId, section_id: sectionId)
    ).eq("id", value: id).execute()
  }

  func updateRecurrence(id: String, value: String?) async throws {
    if let value {
      try await client.from("tasks").update(["recorrencia": value]).eq("id", value: id).execute()
    } else {
      try await client.from("tasks").update(["recorrencia": Optional<String>.none]).eq("id", value: id).execute()
    }
  }

  func updateTaskOrders(_ items: [(id: String, order: Int)]) async throws {
    for item in items {
      try await client.from("tasks").update(["ordem": item.order]).eq("id", value: item.id).execute()
    }
  }
}

/// JSONEncoder padrão omite nil — sem isso o Postgres pode aplicar default em `prioridade`.
private struct NextOccurrenceInsertPayload: Encodable {
  let titulo: String
  let descricao: String?
  let prioridade: String?
  let project_id: String?
  let section_id: String?
  let data_vencimento: String
  let hora: String?
  let user_id: UUID
  let concluida: Bool
  let recorrencia: String
  let whatsapp_rotina: Bool
  let ordem: Int?

  enum CodingKeys: String, CodingKey {
    case titulo, descricao, prioridade, project_id, section_id, data_vencimento, hora, user_id, concluida, recorrencia, whatsapp_rotina, ordem
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(titulo, forKey: .titulo)
    if let descricao {
      try c.encode(descricao, forKey: .descricao)
    } else {
      try c.encodeNil(forKey: .descricao)
    }
    if let prioridade {
      try c.encode(prioridade, forKey: .prioridade)
    } else {
      try c.encodeNil(forKey: .prioridade)
    }
    if let project_id {
      try c.encode(project_id, forKey: .project_id)
    } else {
      try c.encodeNil(forKey: .project_id)
    }
    if let section_id {
      try c.encode(section_id, forKey: .section_id)
    } else {
      try c.encodeNil(forKey: .section_id)
    }
    try c.encode(data_vencimento, forKey: .data_vencimento)
    if let hora {
      try c.encode(hora, forKey: .hora)
    } else {
      try c.encodeNil(forKey: .hora)
    }
    try c.encode(user_id, forKey: .user_id)
    try c.encode(concluida, forKey: .concluida)
    try c.encode(recorrencia, forKey: .recorrencia)
    try c.encode(whatsapp_rotina, forKey: .whatsapp_rotina)
    if let ordem {
      try c.encode(ordem, forKey: .ordem)
    } else {
      try c.encodeNil(forKey: .ordem)
    }
  }
}

private struct CreateTaskInsertPayload: Encodable {
  let titulo: String
  let descricao: String?
  let prioridade: String?
  let project_id: String?
  let section_id: String?
  let data_vencimento: String?
  let hora: String?
  let user_id: UUID
  let concluida: Bool

  enum CodingKeys: String, CodingKey {
    case titulo, descricao, prioridade, project_id, section_id, data_vencimento, hora, user_id, concluida
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(titulo, forKey: .titulo)
    if let descricao {
      try c.encode(descricao, forKey: .descricao)
    } else {
      try c.encodeNil(forKey: .descricao)
    }
    if let prioridade {
      try c.encode(prioridade, forKey: .prioridade)
    } else {
      try c.encodeNil(forKey: .prioridade)
    }
    if let project_id {
      try c.encode(project_id, forKey: .project_id)
    } else {
      try c.encodeNil(forKey: .project_id)
    }
    if let section_id {
      try c.encode(section_id, forKey: .section_id)
    } else {
      try c.encodeNil(forKey: .section_id)
    }
    if let data_vencimento {
      try c.encode(data_vencimento, forKey: .data_vencimento)
    } else {
      try c.encodeNil(forKey: .data_vencimento)
    }
    if let hora {
      try c.encode(hora, forKey: .hora)
    } else {
      try c.encodeNil(forKey: .hora)
    }
    try c.encode(user_id, forKey: .user_id)
    try c.encode(concluida, forKey: .concluida)
  }
}
