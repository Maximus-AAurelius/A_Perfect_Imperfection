-- ============================================================
-- Perfect Imperfection — functional + security updates (2026-07-15)
-- Run in the Supabase SQL Editor AFTER: schema.sql, storage_photos.sql,
-- discovery.sql, chat.sql. Safe to re-run (idempotent).
--
-- Fixes / adds:
--   1. Discovery v2 — excludes people you already swiped on, applies your
--      age preferences, and refuses to serve non-active (banned/suspended)
--      callers.
--   2. Messaging — banned/suspended users can no longer send messages in
--      existing matches (was only enforced at match creation).
--   3. Blocked list — RPC so Settings can show WHO you blocked (RLS hides
--      blocked profiles from normal selects, so names showed as "Unknown").
--   4. Account deletion — also removes the user's photo objects from the
--      private storage bucket so no orphaned images remain after deletion.
--   5. Admin moderation RPCs — real, audited server-side actions for the
--      admin dashboard: list reports, resolve report, warn/suspend/ban/unban.
--      All check admin_users membership server-side and log to
--      moderation_actions.
-- ============================================================

-- 1) Discovery v2 ---------------------------------------------------------
create or replace function public.discover_profiles()
returns table (id uuid, full_name text, age int, city text, bio text, gender text,
  interests text[], photo_verified boolean)
language sql stable security definer set search_path = public
as $$
  select p.id, p.full_name,
    extract(year from age(current_date, p.date_of_birth))::int,
    case when p.hide_location then null else p.city end,
    p.bio, p.gender, p.interests, p.photo_verified
  from public.profiles p
  join public.profiles me on me.user_id = auth.uid()
  where p.user_id <> auth.uid()
    and me.moderation_status = 'active'
    and p.moderation_status = 'active'
    and extract(year from age(current_date, p.date_of_birth))::int
        between me.age_min and me.age_max
    and not exists (
      select 1 from public.swipes s
      where s.swiper_profile_id = me.id and s.target_profile_id = p.id
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_profile_id = me.id and b.blocked_profile_id = p.id)
         or (b.blocker_profile_id = p.id and b.blocked_profile_id = me.id)
    )
  order by p.created_at desc
  limit 100
$$;
revoke all on function public.discover_profiles() from public, anon;
grant execute on function public.discover_profiles() to authenticated;

-- 2) Only active accounts can send messages --------------------------------
drop policy if exists messages_participant_insert on public.messages;
create policy messages_participant_insert on public.messages
for insert to authenticated
with check (
  sender_profile_id = public.my_profile_id()
  and exists (
    select 1 from public.profiles sp
    where sp.id = messages.sender_profile_id and sp.moderation_status = 'active'
  )
  and exists (
    select 1 from public.matches m
    where m.id = messages.match_id
      and m.status = 'matched'
      and sender_profile_id in (m.profile_a, m.profile_b)
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_profile_id = m.profile_a and b.blocked_profile_id = m.profile_b)
           or (b.blocker_profile_id = m.profile_b and b.blocked_profile_id = m.profile_a)
      )
  )
);

-- 3) Blocked list with names ------------------------------------------------
create or replace function public.get_my_blocks()
returns table (block_id uuid, blocked_profile_id uuid, full_name text, blocked_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select b.id, b.blocked_profile_id, p.full_name, b.created_at
  from public.blocks b
  join public.profiles p on p.id = b.blocked_profile_id
  where b.blocker_profile_id = public.my_profile_id()
  order by b.created_at desc
$$;
revoke all on function public.get_my_blocks() from public, anon;
grant execute on function public.get_my_blocks() to authenticated;

-- 4) Account deletion also clears storage objects ---------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'Not authenticated';
  end if;

  -- Remove the user's photo objects from the private bucket first; the
  -- auth.users delete then cascades through profiles/photos/etc. rows.
  delete from storage.objects
  where bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = me::text;

  delete from auth.users where id = me;
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 5) Admin moderation RPCs ---------------------------------------------------
-- All of these re-check admin membership server-side; never trust the client.

create or replace function public.admin_list_reports()
returns table (id uuid, reporter_name text, reported_name text,
  reported_profile_id uuid, reason text, detail text, status text,
  is_zero_tolerance boolean, created_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select r.id, rp.full_name, tp.full_name, r.reported_profile_id,
         r.reason, r.detail, r.status, r.is_zero_tolerance, r.created_at
  from public.reports r
  join public.profiles rp on rp.id = r.reporter_profile_id
  join public.profiles tp on tp.id = r.reported_profile_id
  where public.is_admin()
  order by (r.status = 'pending') desc, r.is_zero_tolerance desc, r.created_at desc
  limit 200
$$;
revoke all on function public.admin_list_reports() from public, anon;
grant execute on function public.admin_list_reports() to authenticated;

create or replace function public.admin_moderate_user(
  p_profile_id uuid,
  p_action text,                  -- 'warn' | 'suspend' | 'ban' | 'unban'
  p_reason_code text default null,
  p_duration_days int default null,
  p_report_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_id uuid;
begin
  select id into admin_id from public.admin_users
  where user_id = auth.uid() and role in ('moderator','admin','owner');
  if admin_id is null then raise exception 'Admin access required'; end if;
  if p_action not in ('warn','suspend','ban','unban') then
    raise exception 'Invalid action';
  end if;

  update public.profiles set
    moderation_status = case p_action
      when 'warn' then 'warned'
      when 'suspend' then 'suspended'
      when 'ban' then 'banned'
      else 'active' end,
    suspended_until = case when p_action = 'suspend'
      then now() + make_interval(days => coalesce(p_duration_days, 7))
      else null end,
    ban_reason_code = case when p_action = 'ban' then p_reason_code else null end,
    last_warned_at = case when p_action = 'warn' then now() else last_warned_at end
  where id = p_profile_id;
  if not found then raise exception 'Profile not found'; end if;

  insert into public.moderation_actions
    (admin_user_id, target_profile_id, report_id, action, reason_code, duration_days)
  values (admin_id, p_profile_id, p_report_id, p_action, p_reason_code, p_duration_days);
end;
$$;
revoke all on function public.admin_moderate_user(uuid,text,text,int,uuid) from public, anon;
grant execute on function public.admin_moderate_user(uuid,text,text,int,uuid) to authenticated;

create or replace function public.admin_resolve_report(
  p_report_id uuid,
  p_outcome text,                 -- 'no_violation' | 'warned' | 'suspended' | 'banned' | 'content_removed'
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_id uuid;
  target uuid;
begin
  select id into admin_id from public.admin_users
  where user_id = auth.uid() and role in ('moderator','admin','owner');
  if admin_id is null then raise exception 'Admin access required'; end if;
  if p_outcome not in ('no_violation','warned','suspended','banned','content_removed') then
    raise exception 'Invalid outcome';
  end if;

  update public.reports
     set status = 'resolved', outcome_code = p_outcome,
         resolved_by = admin_id, resolved_at = now()
   where id = p_report_id
   returning reported_profile_id into target;
  if target is null then raise exception 'Report not found'; end if;

  insert into public.moderation_actions
    (admin_user_id, target_profile_id, report_id, action, reason_detail)
  values (admin_id, target, p_report_id, 'resolve_report', p_note);
end;
$$;
revoke all on function public.admin_resolve_report(uuid,text,text) from public, anon;
grant execute on function public.admin_resolve_report(uuid,text,text) to authenticated;

-- Known limits (accepted for MVP, revisit later):
--   * 'suspended' does not auto-expire; unban is a manual admin action even
--     after suspended_until passes.
--   * Superlikes are stored as plain likes by create_match_if_mutual.
--   * Photo-level moderation status is not yet enforced in discovery.
