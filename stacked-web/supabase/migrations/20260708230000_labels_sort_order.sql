-- Ordem manual de etiquetas no gerenciador (picker e filtros seguem sort_order).

ALTER TABLE public.labels
  ADD COLUMN IF NOT EXISTS sort_order int NOT NULL DEFAULT 0;

-- Preserva ordem alfabética atual como ponto de partida por usuário.
WITH ranked AS (
  SELECT
    id,
    row_number() OVER (PARTITION BY user_id ORDER BY lower(nome) ASC, nome ASC) - 1 AS rn
  FROM public.labels
)
UPDATE public.labels AS l
SET sort_order = r.rn
FROM ranked AS r
WHERE l.id = r.id;

CREATE INDEX IF NOT EXISTS idx_labels_user_sort
  ON public.labels (user_id, sort_order, nome);

COMMENT ON COLUMN public.labels.sort_order IS 'Ordem manual no gerenciador de etiquetas; menor = primeiro.';
