-- Web Mercator global hex grid migration.
-- Existing tiles are re-centered from the old equirectangular grid into the
-- Mercator grid. Backups are kept; captured_tiles triggers are disabled during
-- the rewrite so the migration does not send push notifications or mutate gold.

begin;

create table if not exists public.hex_grid_migrations (
  version text primary key,
  applied_at timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1 from public.hex_grid_migrations where version = 'mercator_v1'
  ) then
    raise exception 'Web Mercator grid migration already applied';
  end if;
end $$;

create schema if not exists migration_backup;
revoke all on schema migration_backup from public;
revoke all on schema migration_backup from anon, authenticated;

create or replace function public.hex_old_center_lat(p_q int, p_r int)
returns double precision
language sql
immutable
parallel safe
as $$
  select 37.5665 + ((1.5 * p_r) * 100.0 / 111320.0)
$$;

create or replace function public.hex_old_center_lng(p_q int, p_r int)
returns double precision
language sql
immutable
parallel safe
as $$
  select 126.9780 +
    (((sqrt(3.0) * p_q) + (sqrt(3.0) / 2.0 * p_r)) * 100.0 /
      (111320.0 * cos(radians(37.5665))))
$$;

create or replace function public.hex_new_coord(
  p_lat double precision,
  p_lng double precision,
  out q int,
  out r int
)
returns record
language plpgsql
immutable
parallel safe
as $$
declare
  v_radius constant double precision := 6378137.0;
  v_lat0 constant double precision := radians(37.5665);
  v_scale constant double precision := cos(v_lat0);
  v_x double precision;
  v_y double precision;
  v_q double precision;
  v_r double precision;
  v_s double precision;
  v_rq int;
  v_rr int;
  v_rs int;
  v_dq double precision;
  v_dr double precision;
  v_ds double precision;
begin
  v_x := v_radius * radians(p_lng - 126.9780) * v_scale / 100.0;
  v_y := v_radius *
    ln(tan(pi() / 4.0 + radians(p_lat) / 2.0) /
      tan(pi() / 4.0 + v_lat0 / 2.0)) *
    v_scale / 100.0;

  v_q := (sqrt(3.0) / 3.0) * v_x - (1.0 / 3.0) * v_y;
  v_r := (2.0 / 3.0) * v_y;
  v_s := -v_q - v_r;

  v_rq := round(v_q::numeric)::int;
  v_rr := round(v_r::numeric)::int;
  v_rs := round(v_s::numeric)::int;

  v_dq := abs(v_rq - v_q);
  v_dr := abs(v_rr - v_r);
  v_ds := abs(v_rs - v_s);

  if v_dq > v_dr and v_dq > v_ds then
    v_rq := -v_rr - v_rs;
  elsif v_dr > v_ds then
    v_rr := -v_rq - v_rs;
  else
    v_rs := -v_rq - v_rr;
  end if;

  q := v_rq;
  r := v_rr;
end;
$$;

create or replace function public.hex_new_q(
  p_lat double precision,
  p_lng double precision
)
returns int
language sql
immutable
parallel safe
as $$
  select q from public.hex_new_coord(p_lat, p_lng)
$$;

create or replace function public.hex_new_r(
  p_lat double precision,
  p_lng double precision
)
returns int
language sql
immutable
parallel safe
as $$
  select r from public.hex_new_coord(p_lat, p_lng)
$$;

create or replace function public.hex_parse_q(p_id text)
returns int
language sql
immutable
parallel safe
as $$
  select case
    when p_id ~ '^hex_-?[0-9]+_-?[0-9]+$' then split_part(p_id, '_', 2)::int
    when p_id ~ '^hex_[0-9]+_-?[0-9]+_-?[0-9]+$' then split_part(p_id, '_', 3)::int
  end
$$;

create or replace function public.hex_parse_r(p_id text)
returns int
language sql
immutable
parallel safe
as $$
  select case
    when p_id ~ '^hex_-?[0-9]+_-?[0-9]+$' then split_part(p_id, '_', 3)::int
    when p_id ~ '^hex_[0-9]+_-?[0-9]+_-?[0-9]+$' then split_part(p_id, '_', 4)::int
  end
$$;

do $$
declare
  v_unknown text;
begin
  select string_agg(format('%I.%I', table_name, column_name), ', ')
    into v_unknown
  from information_schema.columns
  where table_schema = 'public'
    and column_name = 'tile_id'
    and table_name not in (
      'tile_photos',
      'user_footprints',
      'user_coins',
      'user_achievement_tiles'
    );

  if v_unknown is not null then
    raise exception 'Unhandled tile_id columns: %', v_unknown;
  end if;
end $$;

create table migration_backup.captured_tiles_20261106 as
select * from public.captured_tiles;

create table migration_backup.profiles_20261106 as
select * from public.profiles;

create table migration_backup.tile_photos_20261106 as
select * from public.tile_photos;

create table migration_backup.user_footprints_20261106 as
select * from public.user_footprints;

create table migration_backup.user_coins_20261106 as
select * from public.user_coins;

create table migration_backup.user_achievement_tiles_20261106 as
select * from public.user_achievement_tiles;

create table migration_backup.map_tile_attributes_20261106 as
select * from public.map_tile_attributes;

create temp table _hex_old_ids (
  old_id text primary key,
  q int,
  r int
) on commit drop;

insert into _hex_old_ids (old_id, q, r)
select id, q, r from public.captured_tiles
on conflict (old_id) do nothing;

insert into _hex_old_ids (old_id, q, r)
select distinct
  tile_id,
  public.hex_parse_q(tile_id),
  public.hex_parse_r(tile_id)
from public.tile_photos
where tile_id is not null
on conflict (old_id) do nothing;

insert into _hex_old_ids (old_id, q, r)
select distinct
  tile_id,
  public.hex_parse_q(tile_id),
  public.hex_parse_r(tile_id)
from public.user_footprints
where tile_id is not null
on conflict (old_id) do nothing;

insert into _hex_old_ids (old_id, q, r)
select distinct
  tile_id,
  public.hex_parse_q(tile_id),
  public.hex_parse_r(tile_id)
from public.user_coins
where tile_id is not null
on conflict (old_id) do nothing;

insert into _hex_old_ids (old_id, q, r)
select distinct
  tile_id,
  public.hex_parse_q(tile_id),
  public.hex_parse_r(tile_id)
from public.user_achievement_tiles
where tile_id is not null
on conflict (old_id) do nothing;

insert into _hex_old_ids (old_id, q, r)
select distinct
  main_base_tile_id,
  public.hex_parse_q(main_base_tile_id),
  public.hex_parse_r(main_base_tile_id)
from public.profiles
where main_base_tile_id is not null
on conflict (old_id) do nothing;

do $$
declare
  v_bad text;
begin
  select string_agg(old_id, ', ')
    into v_bad
  from _hex_old_ids
  where q is null or r is null;

  if v_bad is not null then
    raise exception 'Unparseable tile ids: %', v_bad;
  end if;
end $$;

do $$
declare
  v_bad text;
begin
  select string_agg(old_id, ', ')
    into v_bad
  from _hex_old_ids
  where old_id !~ '^hex_-?[0-9]+_-?[0-9]+$';

  if v_bad is not null then
    raise exception 'Non-100m tile ids require a separate migration: %', v_bad;
  end if;
end $$;

create table migration_backup.hex_grid_migration_map_20261106 (
  old_id text primary key,
  old_q int not null,
  old_r int not null,
  new_q int not null,
  new_r int not null,
  new_id text not null,
  center_lat double precision,
  center_lng double precision,
  is_captured boolean not null default false,
  captured_at timestamptz,
  capture_count int,
  user_id uuid,
  color_hex text,
  capture_status text,
  survivor_old_id text,
  total_capture_count int
);

insert into migration_backup.hex_grid_migration_map_20261106 (
  old_id, old_q, old_r, new_q, new_r, new_id,
  center_lat, center_lng, is_captured,
  captured_at, capture_count, user_id, color_hex, capture_status
)
select
  o.old_id,
  o.q,
  o.r,
  c.q,
  c.r,
  'hex_' || c.q || '_' || c.r,
  public.hex_old_center_lat(o.q, o.r),
  public.hex_old_center_lng(o.q, o.r),
  (t.id is not null),
  t.captured_at,
  t.capture_count,
  t.user_id,
  t.color_hex,
  t.capture_status
from _hex_old_ids o
left join public.captured_tiles t on t.id = o.old_id
cross join lateral public.hex_new_coord(
  public.hex_old_center_lat(o.q, o.r),
  public.hex_old_center_lng(o.q, o.r)
) c;

create table migration_backup.hex_grid_migration_groups_20261106 (
  new_id text primary key,
  survivor_old_id text not null,
  total_capture_count int,
  max_captured_at timestamptz,
  user_id uuid,
  color_hex text,
  capture_status text
);

insert into migration_backup.hex_grid_migration_groups_20261106 (
  new_id, survivor_old_id, total_capture_count, max_captured_at,
  user_id, color_hex, capture_status
)
select
  new_id,
  (array_agg(old_id order by captured_at desc nulls last, capture_count desc nulls last, old_id))[1],
  sum(coalesce(capture_count, 1))::int,
  max(captured_at),
  (array_agg(user_id order by captured_at desc nulls last, capture_count desc nulls last, old_id))[1],
  (array_agg(color_hex order by captured_at desc nulls last, capture_count desc nulls last, old_id))[1],
  (array_agg(capture_status order by captured_at desc nulls last, capture_count desc nulls last, old_id))[1]
from migration_backup.hex_grid_migration_map_20261106
where is_captured
group by new_id;

update migration_backup.hex_grid_migration_map_20261106 m
set survivor_old_id = g.survivor_old_id,
    total_capture_count = g.total_capture_count
from migration_backup.hex_grid_migration_groups_20261106 g
where m.new_id = g.new_id;

update migration_backup.hex_grid_migration_map_20261106
set survivor_old_id = old_id
where survivor_old_id is null;

update public.tile_photos p
set tile_id = m.new_id
from migration_backup.hex_grid_migration_map_20261106 m
where p.tile_id = m.old_id;

update public.profiles p
set main_base_tile_id = m.new_id
from migration_backup.hex_grid_migration_map_20261106 m
where p.main_base_tile_id = m.old_id;

update public.user_footprints f
set tile_id = m.new_id || '::' || f.ctid::text
from migration_backup.hex_grid_migration_map_20261106 m
where f.tile_id = m.old_id;

delete from public.user_footprints a
using public.user_footprints b
where a.ctid > b.ctid
  and a.user_id = b.user_id
  and split_part(a.tile_id, '::', 1) = split_part(b.tile_id, '::', 1);

update public.user_footprints
set tile_id = split_part(tile_id, '::', 1)
where tile_id like '%::%';

update public.user_coins c
set tile_id = m.new_id || '::' || c.ctid::text,
    q = m.new_q,
    r = m.new_r
from migration_backup.hex_grid_migration_map_20261106 m
where c.tile_id = m.old_id;

delete from public.user_coins a
using public.user_coins b
where a.ctid > b.ctid
  and a.user_id = b.user_id
  and split_part(a.tile_id, '::', 1) = split_part(b.tile_id, '::', 1);

update public.user_coins
set tile_id = split_part(tile_id, '::', 1)
where tile_id like '%::%';

update public.user_achievement_tiles t
set tile_id = m.new_id || '::' || t.ctid::text
from migration_backup.hex_grid_migration_map_20261106 m
where t.tile_id = m.old_id;

delete from public.user_achievement_tiles a
using public.user_achievement_tiles b
where a.ctid > b.ctid
  and a.user_id = b.user_id
  and a.achievement_id = b.achievement_id
  and split_part(a.tile_id, '::', 1) = split_part(b.tile_id, '::', 1);

update public.user_achievement_tiles
set tile_id = split_part(tile_id, '::', 1)
where tile_id like '%::%';

create temp table _hex_attr_map on commit drop as
select
  a.id as old_id,
  a.q as old_q,
  a.r as old_r,
  c.q as new_q,
  c.r as new_r,
  c.q::text || '_' || c.r::text as new_id,
  a.type_id,
  a.memo,
  a.updated_at
from public.map_tile_attributes a
cross join lateral public.hex_new_coord(
  public.hex_old_center_lat(a.q, a.r),
  public.hex_old_center_lng(a.q, a.r)
) c;

update public.map_tile_attributes a
set id = x.new_id || '::' || a.ctid::text,
    q = x.new_q,
    r = x.new_r
from _hex_attr_map x
where a.id = x.old_id;

delete from public.map_tile_attributes a
using public.map_tile_attributes b
where a.ctid > b.ctid
  and split_part(a.id, '::', 1) = split_part(b.id, '::', 1);

update public.map_tile_attributes
set id = split_part(id, '::', 1)
where id like '%::%';

alter table public.captured_tiles disable trigger "send-push-webhook";
alter table public.captured_tiles disable trigger trg_captured_tile_change;

update public.captured_tiles
set id = '__hex_migrating__' || id;

delete from public.captured_tiles t
using migration_backup.hex_grid_migration_map_20261106 m
where t.id = '__hex_migrating__' || m.old_id
  and m.is_captured
  and m.old_id <> m.survivor_old_id;

update public.captured_tiles t
set id = m.new_id,
    q = m.new_q,
    r = m.new_r,
    capture_count = g.total_capture_count,
    captured_at = g.max_captured_at,
    user_id = g.user_id,
    color_hex = g.color_hex,
    capture_status = coalesce(g.capture_status, 'captured')
from migration_backup.hex_grid_migration_map_20261106 m
join migration_backup.hex_grid_migration_groups_20261106 g
  on g.new_id = m.new_id
where t.id = '__hex_migrating__' || m.old_id
  and m.is_captured
  and m.old_id = m.survivor_old_id;

update public.profiles p
set captured_tiles_count = coalesce(
  (select count(*) from public.captured_tiles t where t.user_id = p.id),
  0
);

alter table public.captured_tiles enable trigger "send-push-webhook";
alter table public.captured_tiles enable trigger trg_captured_tile_change;

do $$
declare
  v_captured int;
  v_groups int;
  v_bad int;
  v_old_refs int;
begin
  select count(*) into v_captured from public.captured_tiles;
  select count(*) into v_groups from migration_backup.hex_grid_migration_groups_20261106;

  if v_captured <> v_groups then
    raise exception 'captured tile count mismatch: % vs %', v_captured, v_groups;
  end if;

  select count(*) into v_bad
  from public.captured_tiles t
  left join migration_backup.hex_grid_migration_groups_20261106 g on g.new_id = t.id
  where g.new_id is null;

  if v_bad <> 0 then
    raise exception 'unmapped captured tiles: %', v_bad;
  end if;

  if exists (
    select 1 from public.captured_tiles where id like '__hex_migrating__%'
  ) then
    raise exception 'temporary captured tile ids remain';
  end if;

  select count(*) into v_old_refs
  from migration_backup.hex_grid_migration_map_20261106 m
  where m.old_id <> m.new_id
    and exists (
      select 1 from public.tile_photos p where p.tile_id = m.old_id
      union all
      select 1 from public.user_footprints f where f.tile_id = m.old_id
      union all
      select 1 from public.user_coins c where c.tile_id = m.old_id
      union all
      select 1 from public.user_achievement_tiles t where t.tile_id = m.old_id
      union all
      select 1 from public.profiles p where p.main_base_tile_id = m.old_id
    )
    and not exists (
      select 1 from migration_backup.hex_grid_migration_map_20261106 n
      where n.new_id = m.old_id
    );

  if v_old_refs <> 0 then
    raise exception 'old tile references remain: %', v_old_refs;
  end if;
end $$;

insert into public.hex_grid_migrations (version) values ('mercator_v1');

insert into supabase_migrations.schema_migrations (version, name)
values ('20261106000000', 'web_mercator_grid')
on conflict (version) do nothing;

notify pgrst, 'reload schema';

commit;
