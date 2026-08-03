-- Notas soltas (post-its) — não são tarefas; bridge opcional via "Virar tarefa" no app.
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text,
  body text not null default '',
  color text not null default 'mint',
  pinned boolean not null default false,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notes_color_check check (
    color in ('mint', 'ash', 'amber', 'violet', 'rose')
  )
);

create index if not exists notes_user_updated_idx
  on public.notes (user_id, pinned desc, updated_at desc)
  where archived_at is null;

alter table public.notes enable row level security;

create policy notes_select_own on public.notes
  for select using (auth.uid() = user_id);

create policy notes_insert_own on public.notes
  for insert with check (auth.uid() = user_id);

create policy notes_update_own on public.notes
  for update using (auth.uid() = user_id);

create policy notes_delete_own on public.notes
  for delete using (auth.uid() = user_id);

create or replace function public.set_notes_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists notes_updated_at on public.notes;
create trigger notes_updated_at
  before update on public.notes
  for each row execute function public.set_notes_updated_at();
