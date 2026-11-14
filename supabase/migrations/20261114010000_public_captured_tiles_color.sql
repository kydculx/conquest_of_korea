-- Public homepage map: expose captured tile coordinates and colors only, never owner ids.
create or replace function public.get_public_captured_tiles()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(jsonb_build_array(q, r, color_hex) order by q, r),
    '[]'::jsonb
  )
  from public.captured_tiles
  where q is not null
    and r is not null;
$$;

revoke all on function public.get_public_captured_tiles() from public;
grant execute on function public.get_public_captured_tiles() to anon, authenticated;
