-- Dia de fechamento da fatura do cartão (ciclo).
alter table public.money_accounts
  add column if not exists closing_day int;

alter table public.money_accounts
  drop constraint if exists money_accounts_closing_day_check;

alter table public.money_accounts
  add constraint money_accounts_closing_day_check check (
    closing_day is null or closing_day between 1 and 31
  );

comment on column public.money_accounts.closing_day is 'Dia de fechamento da fatura (1–31). Só crédito.';
