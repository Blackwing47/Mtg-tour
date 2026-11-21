/* MTG Tour: Update für Tischnummern und Zusatzzeit pro Tisch. */
/* Kann mehrfach ausgeführt werden. Vorhandene Daten bleiben erhalten. */

/* ---------- Tische und Zusatzzeit pro Tisch ---------- */
/* Jeder Pod-Zähler mit Tischnummer meldet sich alle paar Sekunden beim laufenden Turnier. */
/* Die Turnierverwaltung kann einzelnen Tischen für die laufende Runde Minuten gutschreiben. */

create table if not exists public.event_tables (
  event_id uuid not null references public.events(id) on delete cascade,
  table_no int not null check (table_no between 1 and 99),
  status text not null default '',
  players text not null default '',
  last_seen timestamptz,
  extra_round int not null default 0,
  extra_minutes int not null default 0,
  primary key (event_id, table_no)
);
alter table public.event_tables enable row level security;
revoke all on public.event_tables from anon, authenticated;
grant select on public.event_tables to authenticated;
drop policy if exists event_tables_select on public.event_tables;
create policy event_tables_select on public.event_tables for select to authenticated using (public.is_organizer());

create or replace function public.live_event_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.events where round_changed_at > now() - interval '12 hours' order by round_changed_at desc limit 1;
$$;

create or replace function public.table_sync(t int, st text default '', pl text default '')
returns table(name text, round_no int, round_minutes int, ends_at timestamptz, paused_ms int, server_now timestamptz, extra_minutes int)
language plpgsql volatile security definer set search_path = public as $$
#variable_conflict use_column
declare
  e uuid := public.live_event_id();
  ev public.events;
  x int := 0;
begin
  if e is null or t is null or t < 1 or t > 99 then return; end if;
  select * into ev from public.events where id = e;
  insert into public.event_tables as et (event_id, table_no, status, players, last_seen)
  values (e, t, left(coalesce(st, ''), 20), left(coalesce(pl, ''), 200), now())
  on conflict (event_id, table_no) do update set status = excluded.status, players = excluded.players, last_seen = excluded.last_seen
  returning (case when et.extra_round = ev.round_no then et.extra_minutes else 0 end) into x;
  return query select ev.name, ev.round_no, ev.round_minutes, ev.round_ends_at, ev.round_paused_ms, now(), x;
end;
$$;

create or replace function public.table_extra(e uuid, t int, minutes int)
returns int language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare
  r int;
  x int;
begin
  if not public.is_organizer() then raise exception 'Nur Turnierverwalter dürfen Zeit einbuchen.'; end if;
  if t is null or t < 1 or t > 99 then raise exception 'Die Tischnummer muss zwischen 1 und 99 liegen.'; end if;
  if minutes is null or minutes < -60 or minutes > 60 then raise exception 'Es gehen höchstens 60 Minuten auf einmal.'; end if;
  select round_no into r from public.events where id = e;
  if r is null then raise exception 'Turnier nicht gefunden.'; end if;
  insert into public.event_tables as et (event_id, table_no, extra_round, extra_minutes)
  values (e, t, r, greatest(0, least(60, minutes)))
  on conflict (event_id, table_no) do update set
    extra_minutes = greatest(0, least(60, (case when et.extra_round = r then et.extra_minutes else 0 end) + minutes)),
    extra_round = r
  returning et.extra_minutes into x;
  return x;
end;
$$;

revoke execute on function public.live_event_id() from public, anon, authenticated;
revoke execute on function public.table_sync(int, text, text) from public;
grant execute on function public.table_sync(int, text, text) to anon, authenticated;
revoke execute on function public.table_extra(uuid, int, int) from public, anon;
grant execute on function public.table_extra(uuid, int, int) to authenticated;

select 'Update für Tische und Zusatzzeit ist eingespielt' as ergebnis;
