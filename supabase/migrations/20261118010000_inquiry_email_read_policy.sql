-- 비로그인 상태에서 접수된 문의(user_id is null)도
-- 같은 이메일로 로그인한 사용자가 자신의 내역으로 확인할 수 있도록 조회 정책을 보완한다.

drop policy if exists "Users can read own inquiries" on public.user_inquiries;
create policy "Users can read own inquiries"
  on public.user_inquiries for select
  to authenticated
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and email = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

notify pgrst, 'reload schema';
