create table if not exists public.daily_moved_tiles_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  stat_date date not null,
  moved_tiles_count integer not null default 0
    check (moved_tiles_count >= 0 and moved_tiles_count <= 1000000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, stat_date)
);

alter table public.daily_moved_tiles_history enable row level security;

drop policy if exists "Players can read own daily moved tiles"
  on public.daily_moved_tiles_history;

create policy "Players can read own daily moved tiles"
  on public.daily_moved_tiles_history
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Admins can select all daily moved tiles"
  on public.daily_moved_tiles_history;

create policy "Admins can select all daily moved tiles"
  on public.daily_moved_tiles_history
  for select
  using (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

create or replace function public.record_daily_moved_tiles()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stat_date date;
  v_count integer;
begin
  if new.last_moved_at is null then
    return new;
  end if;

  if new.daily_moved_tiles_count is not distinct from old.daily_moved_tiles_count then
    return new;
  end if;

  v_stat_date := (new.last_moved_at at time zone 'utc')::date;
  v_count := greatest(coalesce(new.daily_moved_tiles_count, 0), 0);

  if v_count <= 0 then
    return new;
  end if;

  begin
    insert into public.daily_moved_tiles_history (
      user_id,
      stat_date,
      moved_tiles_count
    ) values (
      new.id,
      v_stat_date,
      v_count
    )
    on conflict (user_id, stat_date) do update
      set moved_tiles_count = greatest(
            public.daily_moved_tiles_history.moved_tiles_count,
            excluded.moved_tiles_count
          ),
          updated_at = now();
  exception when others then
    raise warning 'daily moved tiles history write failed: %', sqlerrm;
  end;

  return new;
end;
$$;

drop trigger if exists trg_record_daily_moved_tiles on public.profiles;
create trigger trg_record_daily_moved_tiles
  after update of daily_moved_tiles_count, last_moved_at on public.profiles
  for each row
  execute function public.record_daily_moved_tiles();

notify pgrst, 'reload schema';
