-- Hygiene: RLS em sections, índices de consulta, policies duplicadas, documentação.

-- ---------------------------------------------------------------------------
-- 1. sections — RLS estava desligado (qualquer client autenticado via anon)
-- ---------------------------------------------------------------------------
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sections_own ON public.sections;
CREATE POLICY sections_own ON public.sections
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = sections.project_id AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = project_id AND p.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 2. labels — policy ALL duplicada (já existem labels_select/insert/update/delete)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários veem suas próprias etiquetas" ON public.labels;

-- ---------------------------------------------------------------------------
-- 3. Índices para consultas frequentes (Hoje, Em breve, projeto, subtarefas)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_projects_user
  ON public.projects (user_id);

CREATE INDEX IF NOT EXISTS idx_labels_user
  ON public.labels (user_id);

CREATE INDEX IF NOT EXISTS idx_tasks_user_pending_due
  ON public.tasks (user_id, concluida, data_vencimento);

CREATE INDEX IF NOT EXISTS idx_tasks_project
  ON public.tasks (project_id)
  WHERE project_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_subtasks_task_ordem
  ON public.subtasks (task_id, ordem);

CREATE INDEX IF NOT EXISTS idx_subtasks_due_pending
  ON public.subtasks (concluida, data_vencimento)
  WHERE data_vencimento IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_task_comments_task
  ON public.task_comments (task_id);

-- ---------------------------------------------------------------------------
-- 4. Validação de prioridade em subtarefas (paridade tasks.prioridade_check)
-- ---------------------------------------------------------------------------
ALTER TABLE public.subtasks
  DROP CONSTRAINT IF EXISTS subtasks_prioridade_check;

ALTER TABLE public.subtasks
  ADD CONSTRAINT subtasks_prioridade_check
  CHECK (
    prioridade IS NULL
    OR prioridade IN ('high', 'medium', 'low')
  );

-- ---------------------------------------------------------------------------
-- 5. Comentários (visíveis no Table Editor do Supabase)
-- ---------------------------------------------------------------------------
COMMENT ON TABLE public.projects IS 'Projetos do usuário (Inbox implícito = project_id NULL em tasks).';
COMMENT ON TABLE public.sections IS 'Seções dentro de um projeto (ex.: Despesas Fixas no Financeiro).';
COMMENT ON TABLE public.tasks IS 'Tarefas principais. data_vencimento=date, hora=time.';
COMMENT ON TABLE public.subtasks IS 'Subtarefas. data_vencimento=timestamptz, hora=text (HH:MM).';
COMMENT ON TABLE public.labels IS 'Etiquetas reutilizáveis por usuário.';
COMMENT ON TABLE public.task_labels IS 'N:N tarefa ↔ etiqueta.';
COMMENT ON TABLE public.task_comments IS 'Comentários em tarefas.';
COMMENT ON TABLE public.saved_filters IS 'Filtros personalizados (criteria JSON).';
COMMENT ON TABLE public.google_calendar_connections IS 'Tokens OAuth Google Calendar — só service role (sem policies).';

COMMENT ON COLUMN public.tasks.hora IS 'Hora do compromisso (tipo time). Notificações iOS/web.';
COMMENT ON COLUMN public.subtasks.hora IS 'Hora do compromisso (texto HH:MM). Notificações iOS.';
COMMENT ON COLUMN public.subtasks.label_ids IS 'Array de UUID de labels (denormalizado; paridade app).';
COMMENT ON COLUMN public.subtasks.descricao IS 'Notas da subtarefa — não usar para hora (usar coluna hora).';
