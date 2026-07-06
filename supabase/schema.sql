-- A Perfect Imperfection Supabase MVP schema
-- Canonical app target for now: static Netlify app backed by Supabase.
-- Run this in the Supabase SQL editor before inviting real testers.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  date_of_birth date,
  city text,
  bio text,
  gender text,
  looking_for text[] not null default '{}',
  interests text[] not null default '{}',
  age_min int not null default 18,
  age_max int not null default 45,
  distance_max int not null default 25,
  hide_location boolean not null default false,
  moderation_status text not null default 'active'
    check (moderation_status in ('active','warned','suspended','banned')),
  suspended_until timestamptz,
  ban_reason_code text,
  last_warned_at timestamptz,
  photo_verified boolean not null default false,
  email_verified boolean not null default false,
  phone_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (age_min >= 18),
  check (age_max >= age_min)
);

alter table public.profiles add column if not exists looking_for text[] not null default '{}';
alter table public.profiles add column if not exists interests text[] not null default '{}';
alter table public.profiles add column if not exists moderation_status text not null default 'active';
alter table public.profiles add column if not exists suspended_until timestamptz;
alter table public.profiles add column if not exists ban_reason_code text;
alter table public.profiles add column if not exists last_warned_at timestamptz;
alter table public.profiles add column if not exists photo_verified boolean not null default false;
alter table public.profiles add column if not exists email_verified boolean not null default false;
alter table public.profiles add column if not exists phone_verified boolean not null default false;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  is_main boolean not null default false,
  moderation_status text not null default 'pending'
    check (moderation_status in ('pending','approved','rejected','removed')),
  created_at timestamptz not null default now()
);

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  swiper_profile_id uuid not null references public.profiles(id) on delete cascade,
  target_profile_id uuid not null references public.profiles(id) on delete cascade,
  direction text not null check (direction in ('pass','like','superlike')),
  created_at timestamptz not null default now(),
  unique (swiper_profile_id, target_profile_id),
  check (swiper_profile_id <> target_profile_id)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  profile_a uuid not null references public.profiles(id) on delete cascade,
  profile_b uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'matched'
    check (status in ('matched','unmatched','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_a, profile_b),
  check (profile_a < profile_b)
);

drop trigger if exists trg_matches_updated_at on public.matches;
create trigger trg_matches_updated_at
before update on public.matches
for each row execute function public.set_updated_at();

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_profile_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) <= 4000),
  created_at timestamptz not null default now()
);

create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_profile_id uuid not null references public.profiles(id) on delete cascade,
  blocked_profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(blocker_profile_id, blocked_profile_id),
  check (blocker_profile_id <> blocked_profile_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_profile_id uuid not null references public.profiles(id) on delete cascade,
  reported_profile_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  detail text,
  context_type text check (context_type in ('profile','message','photo','match')),
  context_id uuid,
  evidence_snapshot jsonb,
  is_zero_tolerance boolean not null default false,
  status text not null default 'pending'
    check (status in ('pending','in_review','resolved')),
  outcome_code text check (outcome_code in ('no_violation','warned','suspended','banned','content_removed')),
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (reporter_profile_id <> reported_profile_id)
);

alter table public.reports add column if not exists detail text;
alter table public.reports add column if not exists context_type text;
alter table public.reports add column if not exists context_id uuid;
alter table public.reports add column if not exists evidence_snapshot jsonb;
alter table public.reports add column if not exists is_zero_tolerance boolean not null default false;
alter table public.reports add column if not exists outcome_code text;
alter table public.reports add column if not exists resolved_by uuid;
alter table public.reports add column if not exists resolved_at timestamptz;

create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  role text not null default 'moderator' check (role in ('moderator','admin','owner')),
  created_at timestamptz not null default now()
);

alter table public.reports drop constraint if exists reports_resolved_by_fkey;
alter table public.reports
  add constraint reports_resolved_by_fkey
  foreign key (resolved_by) references public.admin_users(id);

create table if not exists public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid not null references public.admin_users(id),
  target_profile_id uuid not null references public.profiles(id) on delete cascade,
  report_id uuid references public.reports(id) on delete set null,
  action text not null check (action in ('warn','suspend','ban','unban','remove_content','resolve_report')),
  reason_code text,
  reason_detail text,
  content_type text,
  content_id uuid,
  duration_days int,
  created_at timestamptz not null default now()
);

create or replace function public.my_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.profiles where user_id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
      and role in ('moderator','admin','owner')
  );
$$;

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
      and role = 'owner'
  );
$$;

create or replace function public.create_match_if_mutual(target_profile uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := public.my_profile_id();
  a uuid;
  b uuid;
  match_id uuid;
begin
  if me is null then
    raise exception 'No profile for current user';
  end if;

  if target_profile = me then
    raise exception 'Cannot match yourself';
  end if;

  if exists (
    select 1 from public.blocks
    where (blocker_profile_id = me and blocked_profile_id = target_profile)
       or (blocker_profile_id = target_profile and blocked_profile_id = me)
  ) then
    return null;
  end if;

  insert into public.swipes (swiper_profile_id, target_profile_id, direction)
  values (me, target_profile, 'like')
  on conflict (swiper_profile_id, target_profile_id)
  do update set direction = excluded.direction, created_at = now();

  if not exists (
    select 1 from public.swipes
    where swiper_profile_id = target_profile
      and target_profile_id = me
      and direction in ('like','superlike')
  ) then
    return null;
  end if;

  a := least(me, target_profile);
  b := greatest(me, target_profile);

  insert into public.matches (profile_a, profile_b, status)
  values (a, b, 'matched')
  on conflict (profile_a, profile_b)
  do update set status = 'matched', updated_at = now()
  returning id into match_id;

  return match_id;
end;
$$;

create index if not exists idx_profiles_user_id on public.profiles(user_id);
create index if not exists idx_profiles_moderation_status on public.profiles(moderation_status);
create index if not exists idx_photos_profile_id on public.photos(profile_id);
create index if not exists idx_swipes_swiper on public.swipes(swiper_profile_id);
create index if not exists idx_swipes_target on public.swipes(target_profile_id);
create index if not exists idx_matches_profile_a on public.matches(profile_a);
create index if not exists idx_matches_profile_b on public.matches(profile_b);
create index if not exists idx_messages_match on public.messages(match_id, created_at);
create index if not exists idx_blocks_blocker on public.blocks(blocker_profile_id);
create index if not exists idx_blocks_blocked on public.blocks(blocked_profile_id);
create index if not exists idx_reports_status on public.reports(status, is_zero_tolerance desc, created_at desc);
create index if not exists idx_reports_reported on public.reports(reported_profile_id);
create index if not exists idx_admin_users_user_id on public.admin_users(user_id);
create index if not exists idx_moderation_actions_target on public.moderation_actions(target_profile_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.photos enable row level security;
alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.admin_users enable row level security;
alter table public.moderation_actions enable row level security;

drop policy if exists profiles_select_safe on public.profiles;
create policy profiles_select_safe on public.profiles
for select to authenticated
using (
  public.is_admin()
  or user_id = auth.uid()
  or (
    moderation_status = 'active'
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_profile_id = public.my_profile_id() and b.blocked_profile_id = profiles.id)
         or (b.blocker_profile_id = profiles.id and b.blocked_profile_id = public.my_profile_id())
    )
  )
);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists profiles_update_own_or_admin on public.profiles;
create policy profiles_update_own_or_admin on public.profiles
for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists photos_owner_or_admin on public.photos;
create policy photos_owner_or_admin on public.photos
for all to authenticated
using (
  public.is_admin()
  or exists (select 1 from public.profiles p where p.id = photos.profile_id and p.user_id = auth.uid())
)
with check (
  public.is_admin()
  or exists (select 1 from public.profiles p where p.id = photos.profile_id and p.user_id = auth.uid())
);

drop policy if exists swipes_owner_or_admin on public.swipes;
create policy swipes_owner_or_admin on public.swipes
for all to authenticated
using (public.is_admin() or swiper_profile_id = public.my_profile_id())
with check (public.is_admin() or swiper_profile_id = public.my_profile_id());

drop policy if exists matches_participant_select on public.matches;
create policy matches_participant_select on public.matches
for select to authenticated
using (public.is_admin() or public.my_profile_id() in (profile_a, profile_b));

drop policy if exists matches_admin_write on public.matches;
create policy matches_admin_write on public.matches
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists messages_participant_select on public.messages;
create policy messages_participant_select on public.messages
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.matches m
    where m.id = messages.match_id
      and m.status = 'matched'
      and public.my_profile_id() in (m.profile_a, m.profile_b)
  )
);

drop policy if exists messages_participant_insert on public.messages;
create policy messages_participant_insert on public.messages
for insert to authenticated
with check (
  sender_profile_id = public.my_profile_id()
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

drop policy if exists blocks_owner_or_admin on public.blocks;
create policy blocks_owner_or_admin on public.blocks
for all to authenticated
using (public.is_admin() or blocker_profile_id = public.my_profile_id())
with check (public.is_admin() or blocker_profile_id = public.my_profile_id());

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own on public.reports
for insert to authenticated
with check (reporter_profile_id = public.my_profile_id());

drop policy if exists reports_select_own_or_admin on public.reports;
create policy reports_select_own_or_admin on public.reports
for select to authenticated
using (public.is_admin() or reporter_profile_id = public.my_profile_id());

drop policy if exists reports_admin_update on public.reports;
create policy reports_admin_update on public.reports
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists admin_users_select_self_or_admin on public.admin_users;
create policy admin_users_select_self_or_admin on public.admin_users
for select to authenticated
using (public.is_admin() or user_id = auth.uid());

drop policy if exists admin_users_owner_write on public.admin_users;
create policy admin_users_owner_write on public.admin_users
for all to authenticated
using (public.is_owner())
with check (public.is_owner());

drop policy if exists moderation_actions_admin_only on public.moderation_actions;
create policy moderation_actions_admin_only on public.moderation_actions
for all to authenticated
using (public.is_admin())
with check (public.is_admin());
