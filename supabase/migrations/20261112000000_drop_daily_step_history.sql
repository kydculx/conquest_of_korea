-- 걸음 수(Health Connect/HealthKit) 데이터는 기기 로컬 저장소에만 보관합니다.
-- 서버 저장을 중단하고, 기존에 저장된 걸음 수 기록과 RPC를 제거합니다.

drop function if exists public.upsert_daily_steps(uuid, date, integer);
drop table if exists public.daily_step_history cascade;

notify pgrst, 'reload schema';
