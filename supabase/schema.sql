-- MTG Tour: Tabellen, Rollen und Zugriffsregeln.
-- Im Supabase-Dashboard unter "SQL Editor" einfügen und ausführen.
-- Das Skript kann mehrfach ausgeführt werden, vorhandene Daten bleiben erhalten.

-- ---------- Tabellen ----------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  role text not null default 'player' check (role in ('player', 'organizer')),
  created_at timestamptz not null default now()
);

-- Eigene Decks eines Spielers. Nur der Besitzer sieht sie.
create table if not exists public.decks (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create index if not exists decks_owner_idx on public.decks(owner);

-- Turniere der Tour.
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  starts_on date,
  locked boolean not null default false,
  created_at timestamptz not null default now()
);

-- Anmeldung eines Spielers zu einem Turnier mit einer Kopie der Deckliste
-- zum Zeitpunkt der Anmeldung. Diese Kopie sehen die Turnierverwalter.
create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  player uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  deck_name text not null check (char_length(deck_name) between 1 and 60),
  deck jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, player)
);
create index if not exists registrations_event_idx on public.registrations(event_id);

-- ---------- Hilfsfunktionen ----------

create or replace function public.is_organizer()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'organizer');
$$;

create or replace function public.event_open(e uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.events where id = e and not locked);
$$;

-- Legt für jedes neue Konto automatisch ein Profil als Spieler an.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, left(coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), nullif(split_part(new.email, '@', 1), ''), 'Spieler'), 40))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists decks_touch on public.decks;
create trigger decks_touch before update on public.decks
  for each row execute function public.touch_updated_at();

drop trigger if exists registrations_touch on public.registrations;
create trigger registrations_touch before update on public.registrations
  for each row execute function public.touch_updated_at();

-- ---------- Rechte ----------
-- Ohne Anmeldung ist nichts lesbar. Die Rolle eines Profils lässt sich aus der App
-- heraus nicht ändern, nur hier im SQL Editor.

revoke all on public.profiles, public.decks, public.events, public.registrations from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;
grant select, insert, update, delete on public.decks, public.events, public.registrations to authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

alter table public.profiles enable row level security;
alter table public.decks enable row level security;
alter table public.events enable row level security;
alter table public.registrations enable row level security;

-- Profile: jeder sieht sein eigenes, Turnierverwalter sehen alle.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_organizer());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Decks: nur der Besitzer.
drop policy if exists decks_owner on public.decks;
create policy decks_owner on public.decks for all to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());

-- Turniere: alle Angemeldeten lesen, Turnierverwalter verwalten.
drop policy if exists events_select on public.events;
create policy events_select on public.events for select to authenticated using (true);

drop policy if exists events_insert on public.events;
create policy events_insert on public.events for insert to authenticated with check (public.is_organizer());

drop policy if exists events_update on public.events;
create policy events_update on public.events for update to authenticated
  using (public.is_organizer()) with check (public.is_organizer());

drop policy if exists events_delete on public.events;
create policy events_delete on public.events for delete to authenticated using (public.is_organizer());

-- Anmeldungen: Spieler sehen und ändern nur ihre eigene, und nur solange das Turnier
-- offen ist. Turnierverwalter sehen und ändern alle.
drop policy if exists registrations_select on public.registrations;
create policy registrations_select on public.registrations for select to authenticated
  using (player = auth.uid() or public.is_organizer());

drop policy if exists registrations_insert on public.registrations;
create policy registrations_insert on public.registrations for insert to authenticated
  with check ((player = auth.uid() and public.event_open(event_id)) or public.is_organizer());

drop policy if exists registrations_update on public.registrations;
create policy registrations_update on public.registrations for update to authenticated
  using ((player = auth.uid() and public.event_open(event_id)) or public.is_organizer())
  with check ((player = auth.uid() and public.event_open(event_id)) or public.is_organizer());

drop policy if exists registrations_delete on public.registrations;
create policy registrations_delete on public.registrations for delete to authenticated
  using ((player = auth.uid() and public.event_open(event_id)) or public.is_organizer());
