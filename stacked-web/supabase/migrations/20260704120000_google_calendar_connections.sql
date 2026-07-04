-- Google Calendar OAuth tokens (server-only via service role)
create table if not exists public.google_calendar_connections (
  user_id uuid primary key references auth.users (id) on delete cascade,
  refresh_token text not null,
  access_token text,
  token_expires_at timestamptz,
  google_account_email text,
  import_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.google_calendar_connections enable row level security;

-- No policies: only service role reads/writes tokens (bypasses RLS)

create or replace function public.set_google_calendar_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists google_calendar_connections_updated_at on public.google_calendar_connections;
create trigger google_calendar_connections_updated_at
  before update on public.google_calendar_connections
  for each row execute function public.set_google_calendar_updated_at();
