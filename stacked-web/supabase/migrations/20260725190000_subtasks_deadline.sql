-- Prazo final (Deadline) em subtarefas — paridade com tasks.deadline.

ALTER TABLE public.subtasks
  ADD COLUMN IF NOT EXISTS deadline date;

COMMENT ON COLUMN public.subtasks.deadline IS
  'Prazo final da subtarefa (date). Independente de data_vencimento. NULL se ausente.';

CREATE INDEX IF NOT EXISTS idx_subtasks_deadline_pending
  ON public.subtasks (deadline)
  WHERE deadline IS NOT NULL AND concluida = false;
