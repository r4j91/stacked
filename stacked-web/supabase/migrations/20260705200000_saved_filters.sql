-- Filtros personalizados salvos (critérios em JSON — paridade FilterCriteria)
create table if not exists public.saved_filters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color text,
  criteria jsonb not null default '{}'::jsonb,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists saved_filters_user_sort_idx
  on public.saved_filters (user_id, sort_order, created_at);

alter table public.saved_filters enable row level security;

create policy saved_filters_select_own on public.saved_filters
  for select using (auth.uid() = user_id);

create policy saved_filters_insert_own on public.saved_filters
  for insert with check (auth.uid() = user_id);

create policy saved_filters_update_own on public.saved_filters
  for update using (auth.uid() = user_id);

create policy saved_filters_delete_own on public.saved_filters
  for delete using (auth.uid() = user_id);

create or replace function public.set_saved_filters_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists saved_filters_updated_at on public.saved_filters;
create trigger saved_filters_updated_at
  before update on public.saved_filters
  for each row execute function public.set_saved_filters_updated_at();
