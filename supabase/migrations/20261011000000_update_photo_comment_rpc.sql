-- 관리자 콘솔 사진 코멘트 수정 RPC (삭제 RPC와 동일 패턴)
-- RLS를 우회하기 위해 SECURITY DEFINER로 실행된다.
-- 사용 후 Supabase 대시보드 SQL 편집기 또는 `supabase db push`로 적용한다.
create or replace function public.update_photo_comment_by_admin(
  p_photo_id uuid,
  p_comment text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.tile_photos
  set comment = coalesce(p_comment, '')
  where id = p_photo_id;
end;
$$;

grant execute on function public.update_photo_comment_by_admin(uuid, text) to authenticated;
grant execute on function public.update_photo_comment_by_admin(uuid, text) to anon;
