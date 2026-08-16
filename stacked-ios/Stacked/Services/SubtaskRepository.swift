import Foundation
import Supabase

enum SubtaskPersistenceError: LocalizedError {
  case notFound

  var errorDescription: String? {
    switch self {
    case .notFound: "Subtarefa não encontrada para salvar."
    }
  }
}

@MainActor
final class SubtaskRepository {
  static let shared = SubtaskRepository()
  private var client: SupabaseClient { SupabaseService.client }
  private init() {}

  func toggleDone(id: String?, taskId: String?, order: Int, done: Bool, title: String? = nil) async throws {
    struct Payload: Encodable {
      let concluida: Bool
      let data_conclusao: String?
    }
    let payload = Payload(
      concluida: done,
      data_conclusao: done ? TaskMapper.isoTimestamp(Date()) : nil
    )
    let resolved = try await persistSubtask(id: id, taskId: taskId, order: order, payload: payload)
    MoneyStore.shared.handleToggleDone(subtaskId: resolved ?? id, done: done, valor: nil, title: title)
  }

  func toggleDone(id: String, done: Bool) async throws {
    try await toggleDone(id: id, taskId: nil, order: 0, done: done)
  }

  /// Paridade lib/services/subtask_repository.dart — id ou task_id+ordem.
  @discardableResult
  func persistSubtask(id: String?, taskId: String?, order: Int, payload: some Encodable) async throws -> String? {
    let normalizedId = normalizedRowId(id)

    if let normalizedId {
      if let resolved = try await updateReturningId(id: normalizedId, payload: payload) {
        return resolved
      }
    }

    guard let taskId, !taskId.isEmpty else { throw SubtaskPersistenceError.notFound }

    if try await updateReturningId(taskId: taskId, order: order, payload: payload) != nil {
      return try await resolveSubtaskId(taskId: taskId, order: order)
    }

    throw SubtaskPersistenceError.notFound
  }

  private func normalizedRowId(_ id: String?) -> String? {
    guard let id else { return nil }
    let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    // idOrFallback usa "taskId:order" — não é UUID válido no banco.
    if trimmed.contains(":") { return nil }
    return trimmed
  }

  private struct IdRow: Decodable { let id: String }

  private func updateReturningId(id: String, payload: some Encodable) async throws -> String? {
    let rows: [IdRow] = try await client
      .from("subtasks")
      .update(payload)
      .eq("id", value: id)
      .select("id")
      .execute()
      .value
    return rows.first?.id
  }

  private func updateReturningId(taskId: String, order: Int, payload: some Encodable) async throws -> String? {
    let rows: [IdRow] = try await client
      .from("subtasks")
      .update(payload)
      .eq("task_id", value: taskId)
      .eq("ordem", value: order)
      .select("id")
      .execute()
      .value
    return rows.first?.id
  }

  private func resolveSubtaskId(taskId: String, order: Int) async throws -> String? {
    let row: IdRow = try await client
      .from("subtasks")
      .select("id")
      .eq("task_id", value: taskId)
      .eq("ordem", value: order)
      .single()
      .execute()
      .value
    return row.id
  }

  func createSubtask(taskId: String, title: String, order: Int) async throws -> String {
    struct InsertPayload: Encodable {
      let task_id: String
      let titulo: String
      let ordem: Int
      let concluida: Bool
    }
    struct Inserted: Decodable { let id: String }

    let row: Inserted = try await client
      .from("subtasks")
      .insert(InsertPayload(task_id: taskId, titulo: title, ordem: order, concluida: false))
      .select("id")
      .single()
      .execute()
      .value
    return row.id
  }

  func createSubtasksBatch(_ rows: [InstallmentSubtaskInsert]) async throws {
    guard !rows.isEmpty else { return }
    try await client.from("subtasks").insert(rows).execute()
  }

  struct InstallmentSubtaskInsert: Encodable {
    let task_id: String
    let titulo: String
    let data_vencimento: String
    let hora: String?
    let valor: Double?
    let concluida: Bool
    let ordem: Int
  }

  func updateTitle(id: String?, taskId: String?, order: Int, title: String) async throws {
    struct Payload: Encodable { let titulo: String }
    try await persistSubtask(id: id, taskId: taskId, order: order, payload: Payload(titulo: title))
  }

  func updateTitle(id: String, title: String) async throws {
    try await updateTitle(id: id, taskId: nil, order: 0, title: title)
  }

  func deleteSubtask(id: String) async throws {
    try await client.from("subtasks").delete().eq("id", value: id).execute()
  }

  func updateMetadata(
    id: String?,
    taskId: String?,
    order: Int,
    priority: Priority?,
    dueDateISO: String?,
    time: String?,
    deadlineISO: String?,
    labelIds: [String]
  ) async throws {
    let full = MetadataPayload(
      prioridade: priority?.rawValue,
      data_vencimento: dueDateISO,
      hora: time,
      deadline: deadlineISO,
      label_ids: labelIds.isEmpty ? nil : labelIds
    )
    do {
      try await persistSubtask(id: id, taskId: taskId, order: order, payload: full)
    } catch {
      guard isMissingOptionalColumn(error) else { throw error }
      let base = MetadataPayload(
        prioridade: priority?.rawValue,
        data_vencimento: nil,
        hora: nil,
        deadline: nil,
        label_ids: nil
      )
      try await persistSubtask(id: id, taskId: taskId, order: order, payload: base)
    }
  }

  func updateMetadata(
    id: String,
    priority: Priority?,
    dueDateISO: String?,
    time: String?,
    deadlineISO: String?,
    labelIds: [String]
  ) async throws {
    try await updateMetadata(
      id: id,
      taskId: nil,
      order: 0,
      priority: priority,
      dueDateISO: dueDateISO,
      time: time,
      deadlineISO: deadlineISO,
      labelIds: labelIds
    )
  }

  func updateValor(id: String?, taskId: String?, order: Int, valor: Double?) async throws {
    struct Payload: Encodable {
      let valor: Double?

      enum CodingKeys: String, CodingKey { case valor }

      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let valor {
          try container.encode(valor, forKey: .valor)
        } else {
          try container.encodeNil(forKey: .valor)
        }
      }
    }
    try await persistSubtask(id: id, taskId: taskId, order: order, payload: Payload(valor: valor))
  }

  func updateIncludeInCashFlow(id: String?, taskId: String?, order: Int, enabled: Bool) async throws {
    struct Payload: Encodable { let incluir_fluxo_caixa: Bool }
    try await persistSubtask(
      id: id,
      taskId: taskId,
      order: order,
      payload: Payload(incluir_fluxo_caixa: enabled)
    )
  }

  func updateDescription(id: String?, taskId: String?, order: Int, description: String?) async throws {
    struct Payload: Encodable { let descricao: String? }
    do {
      try await persistSubtask(id: id, taskId: taskId, order: order, payload: Payload(descricao: description))
    } catch {
      guard isMissingOptionalColumn(error), error.localizedDescription.contains("descricao") else { throw error }
    }
  }

  func isMissingDescriptionColumn(_ error: Error) -> Bool {
    isMissingOptionalColumn(error) && error.localizedDescription.lowercased().contains("descricao")
  }

  private func isMissingOptionalColumn(_ error: Error) -> Bool {
    let msg = error.localizedDescription.lowercased()
    return msg.contains("data_vencimento")
      || msg.contains("label_ids")
      || msg.contains("descricao")
      || msg.contains("hora")
      || msg.contains("deadline")
  }

  // MARK: - Agenda (Hoje / Em breve)

  private static let scheduleParentSelect = """
    id, titulo, descricao, prioridade, hora, ordem, concluida, data_vencimento, recorrencia, whatsapp_rotina, incluir_fluxo_caixa, project_id, section_id,
    projects ( nome ),
    task_labels ( sort_order, labels ( id, nome, cor ) )
    """

  private static let scheduleSubtaskSelect = """
    id, titulo, descricao, concluida, ordem, prioridade, valor, incluir_fluxo_caixa, data_vencimento, hora, deadline, label_ids, task_id,
    tasks ( \(scheduleParentSelect) )
    """

  /// Subtarefas pendentes com data — para Em breve e calendário.
  func fetchDatedPendingScheduleEntries() async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .not("data_vencimento", operator: .is, value: "null")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  /// Subtarefas com vencimento até hoje — para Hoje (inclui atrasadas).
  func fetchTodayScheduleEntries() async throws -> [SubtaskScheduleEntry] {
    let today = TaskMapper.dateString(Date())
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .or("data_vencimento.lte.\(today),deadline.lte.\(today)")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  func fetchOverdueScheduleEntries(todayStr: String) async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .or("data_vencimento.lt.\(todayStr),deadline.lt.\(todayStr)")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  func fetchTodayOnlyScheduleEntries(todayStr: String) async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .eq("data_vencimento", value: todayStr)
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  func fetchWeekScheduleEntries(todayStr: String, weekStr: String) async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .gt("data_vencimento", value: todayStr)
      .lte("data_vencimento", value: weekStr)
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  // MARK: - Home aggregates

  func countOverdueScheduleEntries(todayStr: String) async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let rows: [IdRow] = try await client
      .from("subtasks")
      .select("id")
      .eq("concluida", value: false)
      .or("data_vencimento.lt.\(todayStr),deadline.lt.\(todayStr)")
      .execute()
      .value
    return rows.count
  }

  func countDueTodayPending(todayStr: String) async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let rows: [IdRow] = try await client
      .from("subtasks")
      .select("id")
      .eq("concluida", value: false)
      .eq("data_vencimento", value: todayStr)
      .execute()
      .value
    return rows.count
  }

  /// Subtarefas concluídas dentro do dia de hoje — entra na meta diária junto
  /// com as tarefas.
  func countCompletedToday(todayStr: String) async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let bounds = TaskMapper.completionDayBounds(
      for: TaskMapper.parseDueDate(todayStr) ?? Date()
    )
    let rows: [IdRow] = try await client
      .from("subtasks")
      .select("id")
      .eq("concluida", value: true)
      .gte("data_conclusao", value: bounds.start)
      .lt("data_conclusao", value: bounds.end)
      .execute()
      .value
    return rows.count
  }

  func countDueInWeekPending(todayStr: String, weekStr: String) async throws -> Int {
    struct IdRow: Decodable { let id: String }
    let rows: [IdRow] = try await client
      .from("subtasks")
      .select("id")
      .eq("concluida", value: false)
      .gt("data_vencimento", value: todayStr)
      .lte("data_vencimento", value: weekStr)
      .execute()
      .value
    return rows.count
  }

  /// Subtarefas pendentes com valor — obrigações financeiras (com ou sem data).
  func fetchPendingValorEntries() async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: false)
      .not("valor", operator: .is, value: "null")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows, requireDueDate: false)
  }

  /// Subtarefas concluídas com valor — histórico do a pagar por mês.
  func fetchCompletedValorEntries() async throws -> [SubtaskScheduleEntry] {
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .eq("concluida", value: true)
      .not("valor", operator: .is, value: "null")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows, requireDueDate: false)
  }

  /// Todas as subtarefas dos pais (pagas e não) — para o snapshot de parcelas.
  func fetchEntriesForParentIds(_ taskIds: [String]) async throws -> [SubtaskScheduleEntry] {
    guard !taskIds.isEmpty else { return [] }
    let rows: [ScheduledSubtaskRowDTO] = try await client
      .from("subtasks")
      .select(Self.scheduleSubtaskSelect)
      .in("task_id", values: taskIds)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows, requireDueDate: false)
  }

  private func mapScheduleEntries(
    _ rows: [ScheduledSubtaskRowDTO],
    requireDueDate: Bool = true
  ) -> [SubtaskScheduleEntry] {
    rows.compactMap { row in
      guard let parentDTO = row.tasks else { return nil }
      let parent = TaskMapper.mapRow(parentDTO)
      let due = TaskMapper.parseDueDate(row.data_vencimento)
      if requireDueDate, due == nil { return nil }
      let deadline = TaskMapper.parseDueDate(row.deadline)
      let done = row.concluida ?? false
      let subtask = Subtask(
        id: row.id,
        taskId: parent.id,
        title: row.titulo ?? "",
        description: row.descricao,
        done: done,
        priority: Priority.parse(row.prioridade),
        order: row.ordem ?? 0,
        valor: row.valor,
        includeInCashFlow: row.incluir_fluxo_caixa ?? true,
        dueDate: due,
        time: row.hora,
        deadline: deadline,
        dueDateChipLabel: due.map { TaskMapper.dueDateChipLabel(for: $0) },
        dueDateChipColor: due.map { TaskMapper.dateColor(for: $0, done: done) },
        deadlineChipLabel: deadline.map { TaskMapper.deadlineChipLabel(for: $0) },
        deadlineChipColor: deadline.map { TaskMapper.deadlineColor(for: $0, done: done) },
        timeDisplay: row.hora.map { TaskMapper.formatTimeDisplay($0) },
        labelIds: row.label_ids ?? []
      )
      return SubtaskScheduleEntry(subtask: subtask, parent: parent)
    }
  }
}

private struct ScheduledSubtaskRowDTO: Decodable {
  let id: String?
  let titulo: String?
  let descricao: String?
  let concluida: Bool?
  let ordem: Int?
  let prioridade: String?
  let valor: Double?
  let incluir_fluxo_caixa: Bool?
  let data_vencimento: String?
  let hora: String?
  let deadline: String?
  let label_ids: [String]?
  let tasks: TaskRowDTO?

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decodeIfPresent(String.self, forKey: .id) {
      id = s
    } else if let u = try? c.decodeIfPresent(UUID.self, forKey: .id) {
      id = u.uuidString
    } else {
      id = nil
    }
    titulo = try c.decodeIfPresent(String.self, forKey: .titulo)
    descricao = try c.decodeIfPresent(String.self, forKey: .descricao)
    concluida = try c.decodeIfPresent(Bool.self, forKey: .concluida)
    ordem = try c.decodeIfPresent(Int.self, forKey: .ordem)
    prioridade = try c.decodeIfPresent(String.self, forKey: .prioridade)
    valor = InstallmentGeneratorLogic.decodeValor(c, forKey: .valor)
    incluir_fluxo_caixa = try c.decodeIfPresent(Bool.self, forKey: .incluir_fluxo_caixa)
    data_vencimento = try c.decodeIfPresent(String.self, forKey: .data_vencimento)
    hora = try c.decodeIfPresent(String.self, forKey: .hora)
    deadline = try c.decodeIfPresent(String.self, forKey: .deadline)
    label_ids = try c.decodeIfPresent([String].self, forKey: .label_ids)
    tasks = try c.decodeIfPresent(TaskRowDTO.self, forKey: .tasks)
  }

  private enum CodingKeys: String, CodingKey {
    case id, titulo, descricao, concluida, ordem, prioridade, valor, incluir_fluxo_caixa, data_vencimento, hora, deadline, label_ids, tasks
  }
}

/// Encoda null explícito para limpar colunas no Supabase (JSONEncoder padrão omite nil).
private struct MetadataPayload: Encodable {
  let prioridade: String?
  let data_vencimento: String?
  let hora: String?
  let deadline: String?
  let label_ids: [String]?

  enum CodingKeys: String, CodingKey {
    case prioridade, data_vencimento, hora, deadline, label_ids
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let prioridade {
      try container.encode(prioridade, forKey: .prioridade)
    } else {
      try container.encodeNil(forKey: .prioridade)
    }
    if let data_vencimento {
      try container.encode(data_vencimento, forKey: .data_vencimento)
    } else {
      try container.encodeNil(forKey: .data_vencimento)
    }
    if let hora {
      try container.encode(hora, forKey: .hora)
    } else {
      try container.encodeNil(forKey: .hora)
    }
    if let deadline {
      try container.encode(deadline, forKey: .deadline)
    } else {
      try container.encodeNil(forKey: .deadline)
    }
    if let label_ids {
      try container.encode(label_ids, forKey: .label_ids)
    } else {
      try container.encodeNil(forKey: .label_ids)
    }
  }
}
