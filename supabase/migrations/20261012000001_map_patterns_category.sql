-- 패턴 분류 컬럼 (alphabet: 알파벳, digit: 숫자, figure: 도형/커스텀)
alter table public.map_patterns
  add column if not exists category text not null default 'figure';

-- 기존 내장 패턴 분류 백필 (단일 문자 ID 기준)
update public.map_patterns set category = 'alphabet' where id ~ '^[A-Z]$';
update public.map_patterns set category = 'digit' where id ~ '^[0-9]$';
