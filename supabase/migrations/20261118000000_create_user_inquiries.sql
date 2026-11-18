-- 앱 내 문의하기 기능.
-- 접수는 Edge Function(inquiry)이 service_role 권한으로 수행하므로 insert 정책을 두지 않는다.
-- 사용자는 자신이 보낸 문의만 조회하고, 관리자는 전체 조회/답변할 수 있다.

create table if not exists public.user_inquiries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text not null,
  category text not null default 'etc'
    check (category in ('bug', 'feature', 'account', 'etc')),
  title text not null
    check (char_length(btrim(title)) between 2 and 120),
  content text not null
    check (char_length(btrim(content)) between 5 and 5000),
  locale text,
  app_version text,
  platform text,
  status text not null default 'open'
    check (status in ('open', 'answered', 'closed')),
  answer text,
  answered_at timestamptz,
  answered_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_inquiries_status_created_idx
  on public.user_inquiries (status, created_at desc);

create index if not exists user_inquiries_user_created_idx
  on public.user_inquiries (user_id, created_at desc);

create index if not exists user_inquiries_email_created_idx
  on public.user_inquiries (lower(email), created_at desc);

alter table public.user_inquiries enable row level security;

drop policy if exists "Users can read own inquiries" on public.user_inquiries;
create policy "Users can read own inquiries"
  on public.user_inquiries for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Admins can read all inquiries" on public.user_inquiries;
create policy "Admins can read all inquiries"
  on public.user_inquiries for select
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "Admins can update inquiries" on public.user_inquiries;
create policy "Admins can update inquiries"
  on public.user_inquiries for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create or replace function public.touch_user_inquiries_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_touch_user_inquiries_updated_at on public.user_inquiries;
create trigger trg_touch_user_inquiries_updated_at
  before update on public.user_inquiries
  for each row
  execute function public.touch_user_inquiries_updated_at();

-- 접수는 Edge Function(service_role)만 수행한다.
-- anon은 접근 권한을 모두 회수하고, authenticated에는 select/update만 허용한다.
revoke all on public.user_inquiries from anon;
revoke insert, delete, truncate, references, trigger on public.user_inquiries from authenticated;
grant select, update on public.user_inquiries to authenticated;

notify pgrst, 'reload schema';
