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
  capture_status text default 'captured',
  capture_count int not null default 1 -- 각 타일마다 점령된 총 횟수 (최초 1, 재점령 시 2, 3...)
);

-- captured_tiles RLS 설정
alter table public.captured_tiles enable row level security;

create policy "Anyone can view captured tiles."
  on captured_tiles for select
  using ( true );

create policy "Authenticated users can capture tiles."
  on captured_tiles for insert
  with check ( auth.role() = 'authenticated' );

create policy "Authenticated users can update captured tiles."
  on captured_tiles for update
  using ( auth.role() = 'authenticated' );

-- [신규] 동시 점령 경합 및 쉴드 선점 제어를 위한 원자적 저장 프로시저(RPC) 정의
CREATE OR REPLACE FUNCTION safe_capture_tile(
  p_tile_id text,
  p_q int,
  p_r int,
  p_user_id uuid,
  p_color_hex text,
  p_bounds jsonb,
  p_target_capture_count int,
  p_shield_duration_seconds int
) RETURNS boolean AS $$
DECLARE
  v_captured_at timestamptz;
  v_current_owner uuid;
BEGIN
  -- 1. 동시성 제어를 위해 행 단위 쓰기 락(Row Lock) 획득 및 최신 데이터 조회
  SELECT captured_at, user_id INTO v_captured_at, v_current_owner
  FROM public.captured_tiles
  WHERE id = p_tile_id
  FOR UPDATE;

  -- 2. 타인이 점령한 타일인 경우, 아직 보호 쉴드 시간이 유효한지 검증
  IF FOUND AND v_current_owner <> p_user_id THEN
    IF v_captured_at + (p_shield_duration_seconds || ' seconds')::interval > now() THEN
      RETURN false; -- 경합 실패 (쉴드 선점됨)
    END IF;
  END IF;

  -- 3. 안전하게 Upsert(점령 저장) 실행
  INSERT INTO public.captured_tiles (id, q, r, user_id, color_hex, bounds, captured_at, capture_count)
  VALUES (p_tile_id, p_q, p_r, p_user_id, p_color_hex, p_bounds, now(), p_target_capture_count)
  ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      color_hex = EXCLUDED.color_hex,
      captured_at = EXCLUDED.captured_at,
      capture_count = EXCLUDED.capture_count;

  RETURN true;
END;
$$ LANGUAGE plpgsql;
