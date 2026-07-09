-- tile_photos 테이블에 comment(간단한 설명) 컬럼 추가
ALTER TABLE public.tile_photos 
ADD COLUMN IF NOT EXISTS comment text;

-- comment 컬럼에 대한 35자 글자수 제한 제약 조건 추가 (데이터 정합성 및 보증성 확보)
ALTER TABLE public.tile_photos 
DROP CONSTRAINT IF EXISTS tile_photos_comment_length_check;

ALTER TABLE public.tile_photos 
ADD CONSTRAINT tile_photos_comment_length_check 
CHECK (char_length(comment) <= 35);

-- 설명 주석 추가
COMMENT ON COLUMN public.tile_photos.comment IS '유저가 사진 촬영 시 함께 등록한 간단한 한 줄 코멘트';
