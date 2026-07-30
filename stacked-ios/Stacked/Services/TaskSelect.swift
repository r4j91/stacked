import Foundation

// Paridade lib/services/task_repository.dart — kTaskSelect
enum TaskSelect {
  /// Busca — sem comentários, recorrência ou campos pesados de subtarefa.
  static let search = """
    id,
    titulo,
    descricao,
    prioridade,
    hora,
    ordem,
    concluida,
    data_vencimento,
    deadline,
    project_id,
    projects ( nome ),
    subtasks ( id, titulo, concluida, ordem, prioridade, data_vencimento, hora, deadline, label_ids ),
    task_labels ( sort_order, labels ( id, nome, cor ) )
    """

  static let unified = """
    id,
    titulo,
    descricao,
    prioridade,
    hora,
    ordem,
    concluida,
    data_vencimento,
    deadline,
    recorrencia,
    whatsapp_rotina,
    project_id,
    section_id,
    projects ( nome ),
    subtasks ( id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, hora, deadline, label_ids ),
    task_labels ( sort_order, labels ( id, nome, cor ) ),
    task_comments ( count )
    """
}
