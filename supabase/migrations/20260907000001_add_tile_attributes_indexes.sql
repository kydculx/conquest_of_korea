-- 맵 타일 속성 테이블 조회 및 인게임 반경 검색 성능 향상을 위한 인덱스 생성

-- 1. q, r 좌표 복합 인덱스 (모바일 인게임 반경 범위 쿼리 최적화)
create index if not exists idx_map_tile_attributes_coords 
  on public.map_tile_attributes (q, r);

-- 2. 타입별 필터링 인덱스 (속성별 타일 통계 및 필터 쿼리 최적화)
create index if not exists idx_map_tile_attributes_type 
  on public.map_tile_attributes (type_id);
