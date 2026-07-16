-- ============================================================
-- Perfect Imperfection — Matches & Chat enablement
-- Run this in the Supabase SQL Editor AFTER schema.sql (+ storage_photos.sql,
-- discovery.sql). Safe to re-run (idempotent).
--
-- Adds:
--   1. Realtime on the messages table (so open chats update live).
--   2. An unmatch() RPC — participants can't UPDATE matches directly under RLS
--      (matches_admin_write is admin-only), so this SECURITY DEFINER function
--      lets a participant set their own match to 'unmatched'.
--
-- Note: message INSERT/SELECT and block/report INSERT are already governed by
-- policies in schema.sql (messages_participant_insert blocks messaging when
-- either party has blocked the other — safety is enforced server-side).
-- ============================================================

-- 1) Realtime on messages -----------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    execute 'alter publication supabase_realtime add table public.messages';
  end if;
end $$;

-- 2) Participant unmatch RPC ---------------------------------------------------
create or replace function public.unmatch(target_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := public.my_profile_id();
begin
  if me is null then
    raise exception 'No profile for current user';
  end if;

  update public.matches
     set status = 'unmatched', updated_at = now()
   where id = target_match_id
     and me in (profile_a, profile_b);

  if not found then
    raise exception 'Match not found or you are not a participant';
  end if;

  -- Require both people to express fresh interest before another match can
  -- form; otherwise the old mutual likes would recreate it immediately.
  delete from public.swipes
   where (swiper_profile_id = me and target_profile_id in (
            select case when profile_a = me then profile_b else profile_a end
            from public.matches where id = target_match_id
          ))
      or (target_profile_id = me and swiper_profile_id in (
            select case when profile_a = me then profile_b else profile_a end
            from public.matches where id = target_match_id
          ));
end;
$$;

revoke all on function public.unmatch(uuid) from public, anon;
grant execute on function public.unmatch(uuid) to authenticated;
