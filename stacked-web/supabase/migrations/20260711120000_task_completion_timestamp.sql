-- Momento real de conclusão (tarefas e subtarefas).
-- Legado: concluida=true sem data_conclusao não entra em "concluídas hoje".

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS data_conclusao timestamptz;

ALTER TABLE public.subtasks
  ADD COLUMN IF NOT EXISTS data_conclusao timestamptz;

COMMENT ON COLUMN public.tasks.data_conclusao IS
  'Timestamp de quando a tarefa foi marcada concluída. NULL se pendente ou legado sem registro.';

COMMENT ON COLUMN public.subtasks.data_conclusao IS
  'Timestamp de quando a subtarefa foi marcada concluída. NULL se pendente ou legado sem registro.';

CREATE INDEX IF NOT EXISTS idx_tasks_user_completed_at
  ON public.tasks (user_id, data_conclusao DESC)
  WHERE concluida = true AND data_conclusao IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_subtasks_completed_at
  ON public.subtasks (data_conclusao DESC)
  WHERE concluida = true AND data_conclusao IS NOT NULL;

CREATE OR REPLACE FUNCTION public.sync_completion_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.concluida IS TRUE THEN
    IF TG_OP = 'INSERT' OR OLD.concluida IS DISTINCT FROM TRUE THEN
      NEW.data_conclusao := COALESCE(NEW.data_conclusao, now());
    END IF;
  ELSE
    NEW.data_conclusao := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tasks_sync_completion_timestamp ON public.tasks;
CREATE TRIGGER tasks_sync_completion_timestamp
  BEFORE INSERT OR UPDATE OF concluida, data_conclusao ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_completion_timestamp();

DROP TRIGGER IF EXISTS subtasks_sync_completion_timestamp ON public.subtasks;
CREATE TRIGGER subtasks_sync_completion_timestamp
  BEFORE INSERT OR UPDATE OF concluida, data_conclusao ON public.subtasks
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_completion_timestamp();
