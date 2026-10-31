-- 가입 시 감지된 디바이스 플랫폼을 저장합니다. (ios, android, web, other)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS device_platform text;

COMMENT ON COLUMN public.profiles.device_platform IS '가입 시 감지된 디바이스 플랫폼 (ios, android, web, other)';
