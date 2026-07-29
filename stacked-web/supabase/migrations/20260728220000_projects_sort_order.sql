-- Ordem manual de projetos na Home / sidebar (paridade labels.sort_order).

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS sort_order int NOT NULL DEFAULT 0;

-- Preserva ordem alfabética atual como ponto de partida por usuário.
WITH ranked AS (
  SELECT
    id,
    row_number() OVER (PARTITION BY user_id ORDER BY lower(nome) ASC, nome ASC) - 1 AS rn
  FROM public.projects
)
UPDATE public.projects AS p
SET sort_order = r.rn
FROM ranked AS r
WHERE p.id = r.id;

CREATE INDEX IF NOT EXISTS idx_projects_user_sort
  ON public.projects (user_id, sort_order, nome);

COMMENT ON COLUMN public.projects.sort_order IS 'Ordem manual na Home/sidebar; menor = primeiro.';
