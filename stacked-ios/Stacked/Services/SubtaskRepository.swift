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

  func toggleDone(id: String?, taskId: String?, order: Int, done: Bool) async throws {
    struct Payload: Encodable { let concluida: Bool }
    _ = try await persistSubtask(id: id, taskId: taskId, order: order, payload: Payload(concluida: done))
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
    labelIds: [String]
  ) async throws {
    let full = MetadataPayload(
      prioridade: priority?.rawValue,
      data_vencimento: dueDateISO,
      hora: time,
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
    labelIds: [String]
  ) async throws {
    try await updateMetadata(
      id: id,
      taskId: nil,
      order: 0,
      priority: priority,
      dueDateISO: dueDateISO,
      time: time,
      labelIds: labelIds
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
  }

  // MARK: - Agenda (Hoje / Em breve)

  private static let scheduleParentSelect = """
    id, titulo, descricao, prioridade, hora, ordem, concluida, data_vencimento, recorrencia, project_id, section_id,
    projects ( nome ),
    task_labels ( labels ( id, nome, cor ) )
    """

  private static let scheduleSubtaskSelect = """
    id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, hora, label_ids, task_id,
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
      .lte("data_vencimento", value: today)
      .not("data_vencimento", operator: .is, value: "null")
      .order("data_vencimento", ascending: true)
      .order("ordem", ascending: true)
      .execute()
      .value
    return mapScheduleEntries(rows)
  }

  private func mapScheduleEntries(_ rows: [ScheduledSubtaskRowDTO]) -> [SubtaskScheduleEntry] {
    rows.compactMap { row in
      guard let parentDTO = row.tasks else { return nil }
      let parent = TaskMapper.mapRow(parentDTO)
      let due = TaskMapper.parseDueDate(row.data_vencimento)
      guard due != nil else { return nil }
      let subtask = Subtask(
        id: row.id,
        taskId: parent.id,
        title: row.titulo ?? "",
        description: row.descricao,
        done: row.concluida ?? false,
        priority: Priority.parse(row.prioridade),
        order: row.ordem ?? 0,
        valor: row.valor,
        dueDate: due,
        time: row.hora,
        dueDateChipLabel: due.map { TaskMapper.dueDateChipLabel(for: $0) },
        dueDateChipColor: due.map { TaskMapper.dateColor(for: $0, done: row.concluida ?? false) },
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
  let data_vencimento: String?
  let hora: String?
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
    valor = try c.decodeIfPresent(Double.self, forKey: .valor)
    data_vencimento = try c.decodeIfPresent(String.self, forKey: .data_vencimento)
    hora = try c.decodeIfPresent(String.self, forKey: .hora)
    label_ids = try c.decodeIfPresent([String].self, forKey: .label_ids)
    tasks = try c.decodeIfPresent(TaskRowDTO.self, forKey: .tasks)
  }

  private enum CodingKeys: String, CodingKey {
    case id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, hora, label_ids, tasks
  }
}

/// Encoda null explícito para limpar colunas no Supabase (JSONEncoder padrão omite nil).
private struct MetadataPayload: Encodable {
  let prioridade: String?
  let data_vencimento: String?
  let hora: String?
  let label_ids: [String]?

  enum CodingKeys: String, CodingKey {
    case prioridade, data_vencimento, hora, label_ids
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
    if let label_ids {
      try container.encode(label_ids, forKey: .label_ids)
    } else {
      try container.encodeNil(forKey: .label_ids)
    }
  }
}
