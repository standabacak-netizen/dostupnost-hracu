-- Dostupnost hráčů: Supabase SQL
-- Vlož celý tento skript do Supabase -> SQL Editor -> New query -> Run

create table if not exists public.rooms (
  room_code text primary key,
  state jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.rooms enable row level security;

drop policy if exists "rooms_select_anon" on public.rooms;
create policy "rooms_select_anon"
on public.rooms for select
to anon
using (true);

drop policy if exists "rooms_insert_anon" on public.rooms;
create policy "rooms_insert_anon"
on public.rooms for insert
to anon
with check (length(room_code) between 3 and 12);

drop policy if exists "rooms_update_anon" on public.rooms;
create policy "rooms_update_anon"
on public.rooms for update
to anon
using (true)
with check (length(room_code) between 3 and 12);

grant select, insert, update on public.rooms to anon;

-- Realtime: umožní klientům dostávat UPDATE/INSERT změny.
alter publication supabase_realtime add table public.rooms;

-- Automaticky aktualizuje updated_at při změně.
create or replace function public.set_rooms_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists rooms_updated_at on public.rooms;
create trigger rooms_updated_at
before update on public.rooms
for each row execute function public.set_rooms_updated_at();
