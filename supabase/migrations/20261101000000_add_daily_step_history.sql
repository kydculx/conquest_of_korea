create table if not exists public.daily_step_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  stat_date date not null,
  step_count integer not null default 0
    check (step_count >= 0 and step_count <= 10000000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, stat_date)
);

alter table public.daily_step_history enable row level security;

drop policy if exists "Players can read own daily steps"
  on public.daily_step_history;

create policy "Players can read own daily steps"
  on public.daily_step_history
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Players can insert own daily steps"
  on public.daily_step_history;

create policy "Players can insert own daily steps"
  on public.daily_step_history
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Players can update own daily steps"
  on public.daily_step_history;

create policy "Players can update own daily steps"
  on public.daily_step_history
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Admins can select all daily steps"
  on public.daily_step_history;

create policy "Admins can select all daily steps"
  on public.daily_step_history
  for select
  using (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

create or replace function public.upsert_daily_steps(
  p_user_id uuid,
  p_local_date date,
  p_step_count integer
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

  if p_step_count is null or p_step_count < 0 then
    return false;
  end if;

  insert into public.daily_step_history (
    user_id,
    stat_date,
    step_count
  ) values (
    v_user_id,
    p_local_date,
    least(p_step_count, 10000000)
  )
  on conflict (user_id, stat_date) do update
    set step_count = greatest(
          public.daily_step_history.step_count,
          excluded.step_count
        ),
        updated_at = now();

  return true;
end;
$$;

revoke all on function public.upsert_daily_steps(
  uuid,
  date,
  integer
) from public;
revoke execute on function public.upsert_daily_steps(
  uuid,
  date,
  integer
) from anon;
grant execute on function public.upsert_daily_steps(
  uuid,
  date,
  integer
) to authenticated;

notify pgrst, 'reload schema';
