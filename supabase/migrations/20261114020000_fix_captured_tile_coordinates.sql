update public.captured_tiles
set q = split_part(id, '_', 2)::integer,
    r = split_part(id, '_', 3)::integer
where id ~ '^hex_-?[0-9]+_-?[0-9]+$'
  and (
    q <> split_part(id, '_', 2)::integer
    or r <> split_part(id, '_', 3)::integer
  );
