-- MTG Tour: Update für die zentrale Rundenfreigabe.
-- Komplett in den SQL Editor von Supabase einfügen, nichts markieren, dann auf Run tippen.
-- Kann mehrfach ausgeführt werden. Vorhandene Daten bleiben erhalten.

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
