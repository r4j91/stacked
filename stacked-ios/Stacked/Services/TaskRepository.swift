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
    let today = TaskMapper.dateString(Date())
    let rows: [TaskRowDTO] = try await client
      .from("tasks")
      .select(TaskSelect.unified)
      .eq("concluida", value: true)
      .or("data_vencimento.is.null,data_vencimento.eq.\(today)")
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
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
    try await client
      .from("tasks")
      .update(["concluida": done])
      .eq("id", value: id)
      .execute()
  }

  func updateTaskDate(id: String, isoDate: String) async throws {
    try await client
      .from("tasks")
      .update(["data_vencimento": isoDate])
      .eq("id", value: id)
      .execute()
  }

  func deleteTask(id: String) async throws {
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

    let today = try await todayRows
    let overdue = try await overdueRows
    let mapped = TaskMapper.mapList(today)
    return HomeTaskSummary(
      todayTotal: mapped.count,
      todayDone: mapped.filter(\.done).count,
      overdueCount: overdue.count
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

    async let completedReq: [IdRow] = client
      .from("tasks")
      .select("id")
      .eq("concluida", value: true)
      .eq("data_vencimento", value: todayStr)
      .execute()
      .value

    let (overdue, today, week, completed) = try await (overdueReq, todayReq, weekReq, completedReq)
    return FilterDashboardCounts(
      overdue: overdue.count,
      today: today.count,
      week: week.count,
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
      query = query.eq("concluida", value: true).eq("data_vencimento", value: todayStr)
    }

    let rows: [TaskRowDTO] = try await query
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .order("id", ascending: true)
      .execute()
      .value
    return TaskMapper.mapList(rows)
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
    struct Payload: Encodable {
      let titulo: String
      let descricao: String?
      let prioridade: String?
      let project_id: String?
      let section_id: String?
      let data_vencimento: String?
      let hora: String?
      let user_id: UUID
      let concluida: Bool
    }
    struct IdRow: Decodable { let id: String }
    let row: IdRow = try await client.from("tasks").insert(
      Payload(
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
}
