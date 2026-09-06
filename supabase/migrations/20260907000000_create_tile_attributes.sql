-- 1. 타일 타입 정의 테이블
create table if not exists public.map_tile_types (
  id int primary key,
  name text not null,
  color_hex text not null,
  description text,
  is_blocked boolean default false,
  created_at timestamptz default now()
);

-- RLS 설정
alter table public.map_tile_types enable row level security;

create policy "Anyone can read tile types"
  on public.map_tile_types for select
  using ( true );

create policy "Authenticated or admin can manage tile types"
  on public.map_tile_types for all
  using ( true )
  with check ( true );

-- 기본 프리셋 타입 시드 데이터
insert into public.map_tile_types (id, name, color_hex, description, is_blocked)
values
  (0, '기본 타일 (Default)', '#334155', '일반 평지 및 기본 타일 구역', false),
  (1, '보너스 거점 (Bonus)', '#fbbf24', '추가 보상 및 점령 포인트 획득 구역', false),
  (2, '진입 불가 (Restricted)', '#ef4444', '플레이어 진입이 차단된 위험 구역', true),
  (3, '트래킹 코스 (Trail)', '#10b981', '걷기/런닝 추천 및 가중치 경로', false),
  (4, '랜드마크 (Landmark)', '#a855f7', '특수 이벤트 및 미션 목적지', false)
on conflict (id) do update set
  name = excluded.name,
  color_hex = excluded.color_hex,
  description = excluded.description,
  is_blocked = excluded.is_blocked;

-- 2. 속성이 부여된 타일 데이터 테이블
create table if not exists public.map_tile_attributes (
  id text primary key, -- 헥사곤 ID ("q_r")
  q int not null,
  r int not null,
  type_id int references public.map_tile_types(id) on delete set default default 0,
  memo text,
  updated_at timestamptz default now()
);

-- RLS 설정
alter table public.map_tile_attributes enable row level security;

create policy "Anyone can read tile attributes"
  on public.map_tile_attributes for select
  using ( true );

create policy "Authenticated or admin can manage tile attributes"
  on public.map_tile_attributes for all
  using ( true )
  with check ( true );
