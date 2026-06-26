-- Migration: Create user_footprints table and set up RLS policies
-- Created At: 2026-06-27 00:18:00 KST

-- 1. user_footprints 테이블 생성
CREATE TABLE IF NOT EXISTS public.user_footprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    tile_id TEXT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_tile_footprint UNIQUE (user_id, tile_id)
);

-- 2. RLS(Row Level Security) 활성화
ALTER TABLE public.user_footprints ENABLE ROW LEVEL SECURITY;

-- 3. 본인의 발자취 데이터만 조회 가능하도록 정책 추가
CREATE POLICY "Users can select their own footprints" ON public.user_footprints
    FOR SELECT USING (auth.uid() = user_id);

-- 4. 본인의 발자취 데이터만 추가 가능하도록 정책 추가
CREATE POLICY "Users can insert their own footprints" ON public.user_footprints
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. user_id 인덱스 추가 (조회 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_user_footprints_user_id ON public.user_footprints(user_id);
