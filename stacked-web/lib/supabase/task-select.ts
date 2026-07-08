/** Paridade lib/services/task_repository.dart — kTaskSelect */
export const TASK_SELECT = `
  id,
  titulo,
  descricao,
  prioridade,
  hora,
  ordem,
  concluida,
  data_vencimento,
  recorrencia,
  project_id,
  section_id,
  projects ( nome ),
  subtasks ( id, titulo, descricao, concluida, ordem, prioridade, valor, data_vencimento, hora, label_ids ),
  task_labels ( labels ( id, nome, cor ) ),
  task_comments ( count )
`;
