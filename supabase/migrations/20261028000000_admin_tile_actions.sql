-- 관리자 대시보드용 타일 강제 점령 / 중립화 RPC.
-- 클라이언트가 소유자 ID를 지정하지 않고, 서버에서 auth.uid()를 사용해
-- 관리자 본인 계정으로만 점령되도록 한다.

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.role IS NOT DISTINCT FROM 'user' THEN
      RETURN NEW;
    END IF;
  ELSIF NEW.role IS NOT DISTINCT FROM OLD.role THEN
    RETURN NEW;
  END IF;

  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    NEW.role := 'user';
  ELSE
    NEW.role := OLD.role;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_role();

CREATE OR REPLACE FUNCTION public.admin_capture_tile(
  p_tile_id text,
  p_q integer,
  p_r integer
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_color_hex text;
  v_next_capture_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin permission required' USING ERRCODE = '42501';
  END IF;

  IF p_tile_id IS NULL OR btrim(p_tile_id) = '' OR p_q IS NULL OR p_r IS NULL THEN
    RAISE EXCEPTION 'invalid tile parameters' USING ERRCODE = '22023';
  END IF;

  SELECT COALESCE(NULLIF(btrim(color_hex), ''), '#00E5FF')
    INTO v_color_hex
  FROM public.profiles
  WHERE id = v_admin_id;

  v_color_hex := COALESCE(v_color_hex, '#00E5FF');

  SELECT COALESCE(capture_count, 0) + 1
    INTO v_next_capture_count
  FROM public.captured_tiles
  WHERE id = p_tile_id;

  v_next_capture_count := COALESCE(v_next_capture_count, 1);

  INSERT INTO public.captured_tiles (
    id, q, r, user_id, color_hex, captured_at, capture_status, capture_count
  ) VALUES (
    p_tile_id, p_q, p_r, v_admin_id, v_color_hex, now(), 'captured', v_next_capture_count
  )
  ON CONFLICT (id) DO UPDATE SET
    q = EXCLUDED.q,
    r = EXCLUDED.r,
    user_id = EXCLUDED.user_id,
    color_hex = EXCLUDED.color_hex,
    captured_at = EXCLUDED.captured_at,
    capture_status = 'captured',
    capture_count = EXCLUDED.capture_count;

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_neutralize_tile(
  p_tile_id text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin permission required' USING ERRCODE = '42501';
  END IF;

  IF p_tile_id IS NULL OR btrim(p_tile_id) = '' THEN
    RAISE EXCEPTION 'invalid tile id' USING ERRCODE = '22023';
  END IF;

  DELETE FROM public.captured_tiles WHERE id = p_tile_id;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.protect_profile_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_capture_tile(text, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_neutralize_tile(text) FROM PUBLIC;

-- Supabase 기본 함수 권한이 anon/authenticated에 직접 부여되므로 명시적으로 회수한다.
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.protect_profile_role() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_capture_tile(text, integer, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_neutralize_tile(text) FROM anon;

GRANT EXECUTE ON FUNCTION public.admin_capture_tile(text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_neutralize_tile(text) TO authenticated;

NOTIFY pgrst, 'reload schema';
