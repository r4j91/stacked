-- Parcelas de compra no cartão: grupo + índice no extrato.
alter table public.money_ledger
  add column if not exists installment_group_id uuid;

alter table public.money_ledger
  add column if not exists installment_index int;

alter table public.money_ledger
  add column if not exists installment_count int;

alter table public.money_ledger
  add column if not exists invoice_applied boolean not null default false;

alter table public.money_ledger
  drop constraint if exists money_ledger_installment_index_check;

alter table public.money_ledger
  add constraint money_ledger_installment_index_check check (
    installment_index is null or installment_index >= 1
  );

alter table public.money_ledger
  drop constraint if exists money_ledger_installment_count_check;

alter table public.money_ledger
  add constraint money_ledger_installment_count_check check (
    installment_count is null or installment_count >= 1
  );

create index if not exists money_ledger_installment_group_idx
  on public.money_ledger (user_id, installment_group_id)
  where installment_group_id is not null;

comment on column public.money_ledger.installment_group_id is 'Plano de parcelas da compra no cartão.';
comment on column public.money_ledger.installment_index is 'Parcela atual (1…N).';
comment on column public.money_ledger.installment_count is 'Total de parcelas.';
comment on column public.money_ledger.invoice_applied is 'Já somada na fatura aberta do cartão.';
