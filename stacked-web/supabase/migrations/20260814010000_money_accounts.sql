-- Contas, cartões e extrato do Dinheiro — sincroniza iPhone ↔ simulador.
create table if not exists public.money_accounts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('checking', 'credit', 'cash')),
  balance double precision not null default 0,
  due_day int,
  invoice_amount double precision,
  parent_account_id uuid references public.money_accounts (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint money_accounts_due_day_check check (
    due_day is null or due_day between 1 and 31
  )
);

create index if not exists money_accounts_user_idx
  on public.money_accounts (user_id, kind, name);

create table if not exists public.money_ledger (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid not null references public.money_accounts (id) on delete cascade,
  occurred_at timestamptz not null default now(),
  amount double precision not null,
  is_income boolean not null default false,
  title text not null default '',
  subtask_id text,
  created_at timestamptz not null default now()
);

create index if not exists money_ledger_user_account_idx
  on public.money_ledger (user_id, account_id, occurred_at);

create table if not exists public.money_obligation_links (
  subtask_id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid not null references public.money_accounts (id) on delete cascade,
  valor double precision not null default 0
);

create index if not exists money_obligation_links_user_idx
  on public.money_obligation_links (user_id);

alter table public.money_accounts enable row level security;
alter table public.money_ledger enable row level security;
alter table public.money_obligation_links enable row level security;

create policy money_accounts_select_own on public.money_accounts
  for select using (auth.uid() = user_id);
create policy money_accounts_insert_own on public.money_accounts
  for insert with check (auth.uid() = user_id);
create policy money_accounts_update_own on public.money_accounts
  for update using (auth.uid() = user_id);
create policy money_accounts_delete_own on public.money_accounts
  for delete using (auth.uid() = user_id);

create policy money_ledger_select_own on public.money_ledger
  for select using (auth.uid() = user_id);
create policy money_ledger_insert_own on public.money_ledger
  for insert with check (auth.uid() = user_id);
create policy money_ledger_update_own on public.money_ledger
  for update using (auth.uid() = user_id);
create policy money_ledger_delete_own on public.money_ledger
  for delete using (auth.uid() = user_id);

create policy money_obligation_links_select_own on public.money_obligation_links
  for select using (auth.uid() = user_id);
create policy money_obligation_links_insert_own on public.money_obligation_links
  for insert with check (auth.uid() = user_id);
create policy money_obligation_links_update_own on public.money_obligation_links
  for update using (auth.uid() = user_id);
create policy money_obligation_links_delete_own on public.money_obligation_links
  for delete using (auth.uid() = user_id);

create or replace function public.set_money_accounts_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists money_accounts_updated_at on public.money_accounts;
create trigger money_accounts_updated_at
  before update on public.money_accounts
  for each row execute function public.set_money_accounts_updated_at();

comment on table public.money_accounts is 'Contas e cartões do Dinheiro (corrente, crédito, dinheiro).';
comment on table public.money_ledger is 'Lançamentos do extrato (entradas, saídas, transferências, fatura).';
comment on table public.money_obligation_links is 'Vínculo subtarefa com valor ↔ conta para descontar ao concluir.';
