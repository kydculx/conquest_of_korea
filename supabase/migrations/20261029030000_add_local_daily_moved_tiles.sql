create table if not exists public.daily_local_moved_tiles_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  stat_date date not null,
  moved_tiles_count integer not null default 0
    check (moved_tiles_count >= 0 and moved_tiles_count <= 1000000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, stat_date)
);

alter table public.daily_local_moved_tiles_history enable row level security;

drop policy if exists "Players can read own local daily moved tiles"
  on public.daily_local_moved_tiles_history;

create policy "Players can read own local daily moved tiles"
  on public.daily_local_moved_tiles_history
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Admins can select all local daily moved tiles"
  on public.daily_local_moved_tiles_history;

create policy "Admins can select all local daily moved tiles"
  on public.daily_local_moved_tiles_history
  for select
  using (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

create or replace function public.increment_moved_tiles_with_local_date(
  p_user_id uuid,
  p_local_date date
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_utc_today date := (now() at time zone 'utc')::date;
begin
  if v_user_id is null or p_user_id is null or v_user_id <> p_user_id then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if p_local_date is null
     or p_local_date < v_utc_today - 2
     or p_local_date > v_utc_today + 2 then
    raise exception 'invalid local date' using errcode = '22023';
  end if;

  if not public.increment_moved_tiles(p_user_id) then
    return false;
  end if;

  insert into public.daily_local_moved_tiles_history (
    user_id,
    stat_date,
    moved_tiles_count
  ) values (
    v_user_id,
    p_local_date,
    1
  )
  on conflict (user_id, stat_date) do update
    set moved_tiles_count =
          public.daily_local_moved_tiles_history.moved_tiles_count + 1,
        updated_at = now();

  return true;
end;
$$;

revoke all on function public.increment_moved_tiles_with_local_date(
  uuid,
  date
) from public;
revoke execute on function public.increment_moved_tiles_with_local_date(
  uuid,
  date
) from anon;
grant execute on function public.increment_moved_tiles_with_local_date(
  uuid,
  date
) to authenticated;

drop trigger if exists trg_record_daily_moved_tiles on public.profiles;
drop function if exists public.record_daily_moved_tiles();

notify pgrst, 'reload schema';
