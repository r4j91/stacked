-- Inclui/exclui a tarefa (e suas parcelas com valor) do fluxo de caixa.
-- Default true: comportamento atual. A PAGAR não é afetado.
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS incluir_fluxo_caixa boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.tasks.incluir_fluxo_caixa IS
  'Se false, obrigações com valor desta tarefa não entram no fluxo de caixa.';
