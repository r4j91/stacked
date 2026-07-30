-- Ordem das etiquetas na tarefa (0 = mais recente / primeira no card).
ALTER TABLE public.task_labels
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.task_labels.sort_order IS
  'Ordem de exibição no card (0 = mais recente / primeira).';

CREATE INDEX IF NOT EXISTS idx_task_labels_task_sort
  ON public.task_labels (task_id, sort_order);
