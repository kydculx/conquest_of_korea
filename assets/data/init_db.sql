-- 사용자 프로필 테이블 생성
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  nickname text unique,
  color_hex text not null,
  main_base_tile_id text,
  created_at timestamptz default now(),
  is_notifications_enabled boolean default true,
  notif_territory_attack boolean default true,
  notif_satellite_complete boolean default true,
  notif_system_notice boolean default true
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

-- 획득한 업적 이력 테이블 생성
create table if not exists public.user_achievements (
  user_id uuid references auth.users(id) on delete cascade not null,
  achievement_id text not null,
  unlocked_at timestamptz default now(),
  primary key (user_id, achievement_id)
);

-- user_achievements RLS 설정
alter table public.user_achievements enable row level security;

create policy "Users can view their own achievements."
  on user_achievements for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own achievements."
  on user_achievements for insert
  with check ( auth.uid() = user_id );

-- 기존 captured_tiles 테이블 수정 (팀 시스템 -> 개인 시스템)
-- 주의: 기존 데이터가 있다면 마이그레이션이 필요할 수 있습니다.
-- 여기서는 기존 테이블이 있다고 가정하고 컬럼을 변경하거나 새로 생성하는 예시입니다.

drop table if exists public.captured_tiles;

create table public.captured_tiles (
  id text primary key, -- 헥사곤 ID
  q int not null,
  r int not null,
  user_id uuid references auth.users(id) on delete cascade,
  color_hex text,
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

create policy "Authenticated users can delete their own captured tiles."
  on captured_tiles for delete
  using ( auth.uid() = user_id );

-- [신규] 구버전 충돌 방지를 위한 안전한 DROP 구문 선언
DROP FUNCTION IF EXISTS public.safe_capture_tile(text, int, int, text, text, jsonb, int, int);
DROP FUNCTION IF EXISTS public.safe_capture_tile(text, int, int, uuid, text, jsonb, int, int);
DROP FUNCTION IF EXISTS public.safe_capture_tile(text, int, int, uuid, text, int, int);
DROP FUNCTION IF EXISTS public.sync_user_gold_and_count(uuid, int);
DROP FUNCTION IF EXISTS public.on_captured_tile_change();
DROP FUNCTION IF EXISTS public.update_user_gold_admin(uuid, numeric);

-- [신규] 동시 점령 경합 및 쉴드 선점 제어를 위한 원자적 저장 프로시저(RPC) 정의
CREATE OR REPLACE FUNCTION safe_capture_tile(
  p_tile_id text,
  p_q int,
  p_r int,
  p_user_id uuid,
  p_color_hex text,
  p_target_capture_count int,
  p_shield_duration_seconds int
) RETURNS boolean
  SECURITY DEFINER
  SET search_path = public
AS $$
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
  INSERT INTO public.captured_tiles (id, q, r, user_id, color_hex, captured_at, capture_count)
  VALUES (p_tile_id, p_q, p_r, p_user_id, p_color_hex, now(), p_target_capture_count)
  ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      color_hex = EXCLUDED.color_hex,
      captured_at = EXCLUDED.captured_at,
      capture_count = EXCLUDED.capture_count;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- [신규] 관리자용 골드 업데이트 RPC 함수 (RLS 우회)
CREATE OR REPLACE FUNCTION public.update_user_gold_admin(
  p_user_id uuid,
  p_gold_amount numeric
) RETURNS void
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET gold = p_gold_amount,
      last_gold_updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- [신규] 골드 획득율(gold_rate) 및 점령 타일 수 기준 골드 및 개수 동기화 펑션
CREATE OR REPLACE FUNCTION public.sync_user_gold_and_count(
  p_user_id uuid,
  p_count_delta int
) RETURNS void
  SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_gold_rate numeric;
  v_last_updated timestamptz;
  v_current_count int;
  v_current_gold numeric;
  v_seconds_diff double precision;
  v_earned_gold numeric;
BEGIN
  -- 1. 골드 획득 배율 획득 (system_settings 테이블 기준, 없으면 1.0)
  BEGIN
    SELECT COALESCE(value::numeric, 1.0) INTO v_gold_rate
    FROM public.system_settings
    WHERE key = 'gold_rate';
  EXCEPTION WHEN OTHERS THEN
    v_gold_rate := 1.0;
  END;
  IF v_gold_rate IS NULL THEN
    v_gold_rate := 1.0;
  END IF;

  -- 2. 해당 유저 프로필 조회 및 Row Lock
  SELECT last_gold_updated_at, captured_tiles_count, gold 
  INTO v_last_updated, v_current_count, v_current_gold
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF FOUND THEN
    -- 3. 오프라인 골드 적립 계산 (마지막 갱신 시각 기준)
    IF v_last_updated IS NULL THEN
      v_last_updated := now();
    END IF;
    
    v_seconds_diff := EXTRACT(EPOCH FROM (now() - v_last_updated));
    IF v_seconds_diff < 0 THEN
      v_seconds_diff := 0;
    END IF;

    v_earned_gold := FLOOR(v_seconds_diff::numeric / 21600.0) * v_current_count * v_gold_rate;

    -- 4. 골드 및 타일 개수 갱신 (개수는 최소 0 보장, 골드는 정수로 가산)
    UPDATE public.profiles
    SET gold = FLOOR(gold + v_earned_gold),
        captured_tiles_count = GREATEST(0, captured_tiles_count + p_count_delta),
        last_gold_updated_at = now()
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- [신규] captured_tiles 테이블 변경 시 호출될 트리거 펑션
CREATE OR REPLACE FUNCTION public.on_captured_tile_change()
RETURNS TRIGGER
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  -- INSERT (새 점령)
  IF (TG_OP = 'INSERT') THEN
    IF NEW.user_id IS NOT NULL THEN
      PERFORM public.sync_user_gold_and_count(NEW.user_id, 1);
    END IF;
    RETURN NEW;

  -- UPDATE (소유자 변경)
  ELSIF (TG_OP = 'UPDATE') THEN
    IF OLD.user_id IS DISTINCT FROM NEW.user_id THEN
      -- 이전 소유자 타일 수 감소 및 골드 정산
      IF OLD.user_id IS NOT NULL THEN
        PERFORM public.sync_user_gold_and_count(OLD.user_id, -1);
      END IF;
      -- 새 소유자 타일 수 증가 및 골드 정산
      IF NEW.user_id IS NOT NULL THEN
        PERFORM public.sync_user_gold_and_count(NEW.user_id, 1);
        -- [추가] 이전 소유자가 존재하는 타일(적 영토)을 점령했을 시 enemy_captured_tiles_count 1 가산
        IF OLD.user_id IS NOT NULL THEN
          UPDATE public.profiles
          SET enemy_captured_tiles_count = COALESCE(enemy_captured_tiles_count, 0) + 1
          WHERE id = NEW.user_id;
        END IF;
      END IF;
    END IF;
    RETURN NEW;

  -- DELETE (점령 취소/삭제)
  ELSIF (TG_OP = 'DELETE') THEN
    IF OLD.user_id IS NOT NULL THEN
      PERFORM public.sync_user_gold_and_count(OLD.user_id, -1);
    END IF;
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- [신규] 트리거 생성
DROP TRIGGER IF EXISTS trg_captured_tile_change ON public.captured_tiles;
DROP TRIGGER IF EXISTS on_captured_tile_change ON public.captured_tiles;
DROP TRIGGER IF EXISTS captured_tiles_trigger ON public.captured_tiles;
DROP TRIGGER IF EXISTS sync_gold_trigger ON public.profiles;

CREATE TRIGGER trg_captured_tile_change
  AFTER INSERT OR UPDATE OR DELETE ON public.captured_tiles
  FOR EACH ROW
  EXECUTE FUNCTION public.on_captured_tile_change();

-- [신규] 기존 데이터 정합성을 위한 초기 1회성 마이그레이션 쿼리
-- 1. 기존의 소수점 골드 데이터를 소수점을 완전히 뗀 정수(FLOOR) 형태로 일괄 보정
UPDATE public.profiles
SET gold = FLOOR(gold);

-- 2. 점령한 타일 개수 동기화
UPDATE public.profiles p
SET captured_tiles_count = COALESCE((
  SELECT COUNT(*) 
  FROM public.captured_tiles c 
  WHERE c.user_id = p.id
), 0);

-- [신규] 플레이어 일일/누적 이동 횟수 1씩 증가 RPC 함수
CREATE OR REPLACE FUNCTION public.increment_moved_tiles(
  p_user_id uuid
) RETURNS boolean
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET daily_moved_tiles_count = COALESCE(daily_moved_tiles_count, 0) + 1,
      total_moved_tiles_count = COALESCE(total_moved_tiles_count, 0) + 1
  WHERE id = p_user_id;

  IF FOUND THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- [신규] profiles 테이블에 위성 관련 카운터 컬럼 안전 추가 DDL
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS satellite_capture_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS satellite_scan_count INT DEFAULT 0;

-- [신규] 위성 원격 점령 성공 횟수 1 증가 DDL
CREATE OR REPLACE FUNCTION public.increment_satellite_capture(
  p_user_id uuid
) RETURNS boolean
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET satellite_capture_count = COALESCE(satellite_capture_count, 0) + 1
  WHERE id = p_user_id;

  IF FOUND THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- [신규] 위성 상세 정보 조회 횟수 1 증가 DDL
CREATE OR REPLACE FUNCTION public.increment_satellite_scan(
  p_user_id uuid
) RETURNS boolean
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET satellite_scan_count = COALESCE(satellite_scan_count, 0) + 1
  WHERE id = p_user_id;

  IF FOUND THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- [신규] profiles 테이블에 다른 모든 업적 및 시스템 관리용 카운터/속성 컬럼 안전 추가 DDL
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gold NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS captured_tiles_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_gold_updated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS daily_moved_tiles_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_moved_tiles_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS enemy_captured_tiles_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS main_base_move_count INT DEFAULT 0;

-- [신규] 본진 이동 횟수 1 증가 RPC 함수
CREATE OR REPLACE FUNCTION public.increment_main_base_move(
  p_user_id uuid
) RETURNS boolean
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET main_base_move_count = COALESCE(main_base_move_count, 0) + 1
  WHERE id = p_user_id;

  IF FOUND THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;



