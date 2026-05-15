-- 사용자 프로필 테이블 생성
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  nickname text unique,
  color_hex text not null,
  created_at timestamptz default now()
);

-- RLS (Row Level Security) 설정
alter table public.profiles enable row level security;

-- 누구나 프로필을 읽을 수 있도록 허용
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

-- 본인의 프로필만 수정할 수 있도록 허용
create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update their own profile."
  on profiles for update
  using ( auth.uid() = id );

-- 기존 captured_tiles 테이블 수정 (팀 시스템 -> 개인 시스템)
-- 주의: 기존 데이터가 있다면 마이그레이션이 필요할 수 있습니다.
-- 여기서는 기존 테이블이 있다고 가정하고 컬럼을 변경하거나 새로 생성하는 예시입니다.

drop table if exists public.captured_tiles;

create table public.captured_tiles (
  id text primary key, -- 헥사곤 ID
  q int not null,
  r int not null,
  user_id uuid references auth.users(id),
  color_hex text,
  bounds jsonb not null,
  captured_at timestamptz default now(),
  capture_status text default 'captured'
);

-- captured_tiles RLS 설정
alter table public.captured_tiles enable row level security;

create policy "Anyone can view captured tiles."
  on captured_tiles for select
  using ( true );

create policy "Authenticated users can capture tiles."
  on captured_tiles for insert
  with check ( auth.role() = 'authenticated' );

create policy "Users can update their own captured tiles."
  on captured_tiles for update
  using ( auth.uid() = user_id );
