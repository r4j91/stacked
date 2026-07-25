-- Prazo final (Deadline) — separado de data_vencimento (quando trabalhar).
-- Paridade Todoist: data = plano; deadline = corte duro. Só data civil (sem hora).

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS deadline date;

COMMENT ON COLUMN public.tasks.deadline IS
  'Prazo final da tarefa (date). Independente de data_vencimento. NULL se ausente.';

CREATE INDEX IF NOT EXISTS idx_tasks_user_deadline
  ON public.tasks (user_id, deadline)
  WHERE deadline IS NOT NULL AND concluida = false;
