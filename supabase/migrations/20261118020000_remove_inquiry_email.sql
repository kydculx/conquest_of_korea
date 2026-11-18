-- 답변을 메일이 아닌 앱 안에서만 확인하므로 문의의 이메일 수집을 중단한다.
-- 문의는 로그인 사용자만 접수할 수 있고, 식별은 user_id로만 수행한다.

drop policy if exists "Users can read own inquiries" on public.user_inquiries;
drop index if exists user_inquiries_email_created_idx;

alter table public.user_inquiries drop column if exists email;

create policy "Users can read own inquiries"
  on public.user_inquiries for select
  to authenticated
  using (user_id = auth.uid());

notify pgrst, 'reload schema';
