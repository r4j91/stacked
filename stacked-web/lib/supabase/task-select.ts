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
  deadline,
  recorrencia,
  whatsapp_rotina,
  incluir_fluxo_caixa,
  project_id,
  section_id,
  projects ( nome ),
  subtasks ( id, titulo, descricao, concluida, ordem, prioridade, valor, incluir_fluxo_caixa, data_vencimento, hora, deadline, label_ids ),
  task_labels ( sort_order, labels ( id, nome, cor ) ),
  task_comments ( count )
`;
