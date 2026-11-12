-- 패턴 타일 중복 금지
-- 한 사용자의 한 타일은 하나의 패턴에만 속할 수 있습니다.
--
-- 1) 기존 중복 정리: 같은 타일을 공유하는 패턴 중 가장 먼저 완성된 패턴만 유지하고,
--    나중에 완성된 패턴의 업적/타일 기록을 삭제합니다. (해당 패턴은 다시 완성 가능)
-- 2) user_achievement_tiles에 (user_id, tile_id) 유니크 제약 추가
-- 3) 패턴 해금을 원자적으로 처리하는 RPC 추가

do $$
begin
  create temp table _overlapping_pattern_achievements on commit drop as
  with pattern_tiles as (
    select t.user_id,
           t.achievement_id,
           t.tile_id,
           coalesce(ua.unlocked_at, 'infinity'::timestamptz) as unlocked_at
    from public.user_achievement_tiles t
    left join public.user_achievements ua
      on ua.user_id = t.user_id
     and ua.achievement_id = t.achievement_id
    where t.achievement_id like 'ACH_PATTERN_%'
  ),
  ranked as (
    select user_id,
           achievement_id,
           tile_id,
           row_number() over (
             partition by user_id, tile_id
             order by unlocked_at asc, achievement_id asc
           ) as rn
    from pattern_tiles
  )
  select distinct user_id, achievement_id
  from ranked
  where rn > 1;

  delete from public.user_achievements ua
  using _overlapping_pattern_achievements o
  where ua.user_id = o.user_id
    and ua.achievement_id = o.achievement_id;

  delete from public.user_achievement_tiles t
  using _overlapping_pattern_achievements o
  where t.user_id = o.user_id
    and t.achievement_id = o.achievement_id;
end $$;

delete from public.user_achievement_tiles a
using public.user_achievement_tiles b
where a.ctid > b.ctid
  and a.user_id = b.user_id
  and a.tile_id = b.tile_id;

alter table public.user_achievement_tiles
  add constraint user_achievement_tiles_user_tile_key
  unique (user_id, tile_id);

-- 4. 원자적 패턴 해금 RPC ----------------------------------------------------
create or replace function public.unlock_pattern_achievement(
  p_user_id uuid,
  p_achievement_id text,
  p_tile_ids text[]
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  -- 본인 세션만 호출 가능
  if auth.uid() is null or auth.uid() <> p_user_id then
    return false;
  end if;

  if p_tile_ids is null or array_length(p_tile_ids, 1) is null then
    return false;
  end if;

  -- 이미 완료된 패턴
  if exists (
    select 1
    from public.user_achievements
    where user_id = p_user_id
      and achievement_id = p_achievement_id
  ) then
    return false;
  end if;

  -- 다른 패턴이 이미 사용한 타일이 하나라도 있으면 거부
  if exists (
    select 1
    from public.user_achievement_tiles
    where user_id = p_user_id
      and tile_id = any(p_tile_ids)
  ) then
    return false;
  end if;

  insert into public.user_achievements (user_id, achievement_id)
  values (p_user_id, p_achievement_id);

  insert into public.user_achievement_tiles (user_id, achievement_id, tile_id)
  select p_user_id, p_achievement_id, unnest(p_tile_ids);

  return true;
exception
  when unique_violation then
    return false;
end;
$$;

grant execute on function public.unlock_pattern_achievement(uuid, text, text[]) to authenticated;

notify pgrst, 'reload schema';
