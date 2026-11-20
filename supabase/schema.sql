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

-- ---------- Rundensteuerung (zentraler Timer für alle Tische) ----------
-- Die Turnierverwaltung gibt eine Runde frei, alle Tisch-Handys übernehmen die Zeit automatisch.
-- Gerechnet wird mit der Uhr des Servers, damit falsch gehende Handyuhren keine Rolle spielen.

alter table public.events add column if not exists code text;
alter table public.events add column if not exists round_no int not null default 0;
alter table public.events add column if not exists round_minutes int not null default 60;
alter table public.events add column if not exists round_ends_at timestamptz;
alter table public.events add column if not exists round_paused_ms int;
alter table public.events add column if not exists round_changed_at timestamptz;
create unique index if not exists events_code_idx on public.events(code);

create or replace function public.new_event_code()
returns text language plpgsql volatile set search_path = public as $$
declare
  chars constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  c text;
begin
  loop
    c := '';
    for i in 1..6 loop
      c := c || substr(chars, 1 + floor(random() * length(chars))::int, 1);
    end loop;
    exit when not exists (select 1 from public.events where code = c);
  end loop;
  return c;
end;
$$;

create or replace function public.events_set_code()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.code is null or new.code = '' then
    new.code := public.new_event_code();
  end if;
  return new;
end;
$$;

drop trigger if exists events_code on public.events;
create trigger events_code before insert on public.events
  for each row execute function public.events_set_code();

update public.events set code = public.new_event_code() where code is null;

-- Steuerung nur für Turnierverwalter: start, pause, resume, extend, stop.
create or replace function public.round_control(e uuid, action text, minutes int default null)
returns public.events language plpgsql security definer set search_path = public as $$
declare
  ev public.events;
  m int;
begin
  if not public.is_organizer() then
    raise exception 'Nur Turnierverwalter dürfen Runden steuern.';
  end if;
  select * into ev from public.events where id = e for update;
  if not found then
    raise exception 'Turnier nicht gefunden.';
  end if;
  if action = 'start' then
    m := coalesce(minutes, ev.round_minutes, 60);
    if m < 1 or m > 240 then raise exception 'Die Rundendauer muss zwischen 1 und 240 Minuten liegen.'; end if;
    update public.events set round_no = round_no + 1, round_minutes = m,
      round_ends_at = now() + make_interval(mins => m), round_paused_ms = null where id = e;
  elsif action = 'pause' then
    update public.events set round_paused_ms = greatest(0, (extract(epoch from (round_ends_at - now())) * 1000)::int)
      where id = e and round_ends_at is not null and round_paused_ms is null;
  elsif action = 'resume' then
    update public.events set round_ends_at = now() + make_interval(secs => round_paused_ms / 1000.0), round_paused_ms = null
      where id = e and round_paused_ms is not null;
  elsif action = 'extend' then
    m := coalesce(minutes, 5);
    if m < 1 or m > 60 then raise exception 'Verlängern geht um 1 bis 60 Minuten.'; end if;
    update public.events set round_ends_at = round_ends_at + make_interval(mins => m),
      round_paused_ms = case when round_paused_ms is null then null else round_paused_ms + m * 60000 end
      where id = e and round_ends_at is not null;
  elsif action = 'stop' then
    update public.events set round_ends_at = null, round_paused_ms = null where id = e;
  else
    raise exception 'Unbekannte Aktion.';
  end if;
  update public.events set round_changed_at = now() where id = e;
  select * into ev from public.events where id = e;
  return ev;
end;
$$;

-- Das laufende Turnier für alle Tische, ohne Anmeldung und ohne Code:
-- das Turnier, dessen Runde die Turnierverwaltung zuletzt gesteuert hat, höchstens 12 Stunden zurück.
create or replace function public.current_round()
returns table(name text, round_no int, round_minutes int, ends_at timestamptz, paused_ms int, server_now timestamptz)
language sql stable security definer set search_path = public as $$
  select e.name, e.round_no, e.round_minutes, e.round_ends_at, e.round_paused_ms, now()
  from public.events e
  where e.round_changed_at > now() - interval '12 hours'
  order by e.round_changed_at desc
  limit 1;
$$;

-- Lesen für die Tische, auch ohne Anmeldung, nur mit dem Turnier-Code.
create or replace function public.round_state(c text)
returns table(name text, round_no int, round_minutes int, ends_at timestamptz, paused_ms int, server_now timestamptz)
language sql stable security definer set search_path = public as $$
  select e.name, e.round_no, e.round_minutes, e.round_ends_at, e.round_paused_ms, now()
  from public.events e where e.code = upper(trim(c));
$$;

revoke execute on function public.round_control(uuid, text, int) from public, anon;
grant execute on function public.round_control(uuid, text, int) to authenticated;
revoke execute on function public.round_state(text) from public;
grant execute on function public.round_state(text) to anon, authenticated;
revoke execute on function public.current_round() from public;
grant execute on function public.current_round() to anon, authenticated;
revoke execute on function public.new_event_code() from public, anon, authenticated;
revoke execute on function public.events_set_code() from public, anon, authenticated;
