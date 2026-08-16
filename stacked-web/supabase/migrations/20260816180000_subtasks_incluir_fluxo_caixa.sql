-- Controle por subtarefa: incluir ou não no fluxo de caixa.
-- Default true. A tarefa-pai (tasks.incluir_fluxo_caixa) continua como interruptor geral.
ALTER TABLE public.subtasks
  ADD COLUMN IF NOT EXISTS incluir_fluxo_caixa boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.subtasks.incluir_fluxo_caixa IS
  'Se false, esta subtarefa com valor não entra no fluxo de caixa.';
