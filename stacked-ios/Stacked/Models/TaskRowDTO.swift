import Foundation

// DTOs para decode do kTaskSelect — paridade Supabase nested select
struct TaskRowDTO: Decodable {
  let id: String
  let titulo: String?
  let descricao: String?
  let prioridade: String?
  let hora: String?
  let ordem: Int?
  let concluida: Bool?
  let data_vencimento: String?
  let recorrencia: String?
  let whatsapp_rotina: Bool?
  let project_id: String?
  let section_id: String?
  let projects: ProjectRefDTO?
  let subtasks: [SubtaskRowDTO]?
  let task_labels: [TaskLabelJoinDTO]?
  let task_comments: [CommentCountDTO]?
}

struct ProjectRefDTO: Decodable {
  let nome: String?
}

struct SubtaskRowDTO: Decodable {
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
  }

  private enum CodingKeys: String, CodingKey {
    case id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, hora, label_ids
  }
}

struct TaskLabelJoinDTO: Decodable {
  let labels: LabelRefDTO?
}

struct LabelRefDTO: Decodable {
  let id: String?
  let nome: String?
  let cor: String?
}

struct CommentCountDTO: Decodable {
  let count: Int?
}

extension TaskRowDTO {
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    if let s = try? c.decode(String.self, forKey: .id) {
      id = s
    } else if let u = try? c.decode(UUID.self, forKey: .id) {
      id = u.uuidString
    } else {
      throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "id missing")
    }
    titulo = try c.decodeIfPresent(String.self, forKey: .titulo)
    descricao = try c.decodeIfPresent(String.self, forKey: .descricao)
    prioridade = try c.decodeIfPresent(String.self, forKey: .prioridade)
    hora = try c.decodeIfPresent(String.self, forKey: .hora)
    ordem = try c.decodeIfPresent(Int.self, forKey: .ordem)
    concluida = try c.decodeIfPresent(Bool.self, forKey: .concluida)
    data_vencimento = try c.decodeIfPresent(String.self, forKey: .data_vencimento)
    recorrencia = try c.decodeIfPresent(String.self, forKey: .recorrencia)
    whatsapp_rotina = try c.decodeIfPresent(Bool.self, forKey: .whatsapp_rotina)
    project_id = Self.stringOrNil(c, .project_id)
    section_id = Self.stringOrNil(c, .section_id)
    projects = try c.decodeIfPresent(ProjectRefDTO.self, forKey: .projects)
    subtasks = try c.decodeIfPresent([SubtaskRowDTO].self, forKey: .subtasks)
    task_labels = try c.decodeIfPresent([TaskLabelJoinDTO].self, forKey: .task_labels)
    task_comments = try c.decodeIfPresent([CommentCountDTO].self, forKey: .task_comments)
  }

  private enum CodingKeys: String, CodingKey {
    case id, titulo, descricao, prioridade, hora, ordem, concluida
    case data_vencimento, recorrencia, whatsapp_rotina, project_id, section_id
    case projects, subtasks, task_labels, task_comments
  }

  private static func stringOrNil(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
    if let s = try? c.decodeIfPresent(String.self, forKey: key) { return s }
    if let u = try? c.decodeIfPresent(UUID.self, forKey: key) { return u.uuidString }
    return nil
  }
}
