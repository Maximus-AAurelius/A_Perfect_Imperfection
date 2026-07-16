-- Adds two optional, owner-authored profile prompts plus a visibility choice:
--   communication_notes — how someone likes to communicate / their pace
--   care_notes           — access needs, identity, or context to be met with care
--   notes_public         — owner's choice: show both prompts on their discovery
--                           card (true) or keep them private to themselves (false).
--                           Defaults to false — private until they opt in.
-- Both notes are free text, nullable, and only ever written through
-- save_my_profile (never a direct table write, matching the rest of this
-- schema's hardening). Run this AFTER schema.sql and updates_2026-07-15.sql
-- in the Supabase SQL editor.

alter table public.profiles add column if not exists communication_notes text;
alter table public.profiles add column if not exists care_notes text;
alter table public.profiles add column if not exists notes_public boolean not null default false;

alter table public.profiles drop constraint if exists profiles_text_lengths;
alter table public.profiles add constraint profiles_text_lengths check (
  char_length(full_name) between 1 and 100
  and (city is null or char_length(city) <= 120)
  and (bio is null or char_length(bio) <= 2000)
  and (communication_notes is null or char_length(communication_notes) <= 600)
  and (care_notes is null or char_length(care_notes) <= 600)
) not valid;

drop function if exists public.save_my_profile(text,text,date,text,text,text,text[],int,int,int);
drop function if exists public.save_my_profile(text,text,date,text,text,text,text[],int,int,int,text,text);

create or replace function public.save_my_profile(
  p_email text,
  p_full_name text,
  p_date_of_birth date,
  p_city text,
  p_gender text,
  p_bio text,
  p_interests text[],
  p_age_min int,
  p_age_max int,
  p_distance_max int,
  p_communication_notes text default null,
  p_care_notes text default null,
  p_notes_public boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  account_email text := nullif(auth.jwt() ->> 'email', '');
  saved_id uuid;
begin
  if me is null then raise exception 'Not authenticated'; end if;
  if nullif(btrim(p_full_name), '') is null or char_length(btrim(p_full_name)) > 100 then
    raise exception 'Full name must be between 1 and 100 characters';
  end if;
  if p_date_of_birth is null or p_date_of_birth > (current_date - interval '18 years')::date then
    raise exception 'You must be at least 18 years old';
  end if;
  if p_age_min < 18 or p_age_max < p_age_min or p_age_max > 120 then raise exception 'Invalid age range'; end if;
  if p_distance_max < 1 or p_distance_max > 500 then raise exception 'Invalid distance'; end if;
  if char_length(coalesce(p_city, '')) > 120 or char_length(coalesce(p_bio, '')) > 2000 then
    raise exception 'Profile text is too long';
  end if;
  if char_length(coalesce(p_communication_notes, '')) > 600 or char_length(coalesce(p_care_notes, '')) > 600 then
    raise exception 'That note is too long — please keep it under 600 characters';
  end if;
  if coalesce(array_length(p_interests, 1), 0) > 30 then raise exception 'Too many interests'; end if;

  insert into public.profiles (
    user_id, email, full_name, date_of_birth, city, gender, bio,
    interests, age_min, age_max, distance_max,
    communication_notes, care_notes, notes_public
  ) values (
    me, coalesce(account_email, p_email), btrim(p_full_name), p_date_of_birth,
    nullif(btrim(p_city), ''), nullif(btrim(p_gender), ''), nullif(btrim(p_bio), ''),
    coalesce(p_interests, '{}'), p_age_min, p_age_max, p_distance_max,
    nullif(btrim(p_communication_notes), ''), nullif(btrim(p_care_notes), ''),
    coalesce(p_notes_public, false)
  )
  on conflict (user_id) do update set
    email = coalesce(account_email, excluded.email), full_name = excluded.full_name,
    date_of_birth = excluded.date_of_birth, city = excluded.city,
    gender = excluded.gender, bio = excluded.bio, interests = excluded.interests,
    age_min = excluded.age_min, age_max = excluded.age_max,
    distance_max = excluded.distance_max,
    communication_notes = excluded.communication_notes,
    care_notes = excluded.care_notes, notes_public = excluded.notes_public
  returning id into saved_id;
  return saved_id;
end;
$$;
revoke all on function public.save_my_profile(text,text,date,text,text,text,text[],int,int,int,text,text,boolean) from public, anon;
grant execute on function public.save_my_profile(text,text,date,text,text,text,text[],int,int,int,text,text,boolean) to authenticated;

-- Discovery v3 — same rules as v2 (updates_2026-07-15.sql) plus the two
-- prompts, which are returned ONLY when their owner set notes_public = true.
-- Return columns changed, so the old function must be dropped first.
drop function if exists public.discover_profiles();
create function public.discover_profiles()
returns table (id uuid, full_name text, age int, city text, bio text, gender text,
  interests text[], photo_verified boolean,
  communication_notes text, care_notes text)
language sql stable security definer set search_path = public
as $$
  select p.id, p.full_name,
    extract(year from age(current_date, p.date_of_birth))::int,
    case when p.hide_location then null else p.city end,
    p.bio, p.gender, p.interests, p.photo_verified,
    case when p.notes_public then p.communication_notes else null end,
    case when p.notes_public then p.care_notes else null end
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

-- Note: communication_notes, care_notes, and notes_public are NOT added to
-- the authenticated column-select grant on public.profiles, so direct table
-- reads by other users never see them. The owner reads them via
-- get_my_profile() (security definer); other users only ever see them
-- through discover_profiles() above, and only when notes_public is true.
