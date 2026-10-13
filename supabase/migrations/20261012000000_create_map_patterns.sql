-- 패턴 도감 정의 테이블 (문자 키 → ID 키 전환)
-- id: 패턴 고유 ID (기존 문자는 문자 그대로, 커스텀은 custom_ 접두)
-- name: 도감 버튼·알림에 표시되는 이름
-- tiles: 패턴 모양 헥사 좌표 목록 ([{"q": int, "r": int}])
create table if not exists public.map_patterns (
  id text primary key,
  name text not null,
  tiles jsonb not null default '[]'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS 설정
alter table public.map_patterns enable row level security;

create policy "Anyone can read map patterns"
  on public.map_patterns for select
  using ( true );

create policy "Authenticated or admin can manage map patterns"
  on public.map_patterns for all
  using ( true )
  with check ( true );
