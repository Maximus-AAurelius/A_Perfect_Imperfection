-- Free-tier Supabase starter schema for A Perfect Imperfection
-- This is intentionally simple and can be expanded later.

create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null,
  full_name text not null,
  email text not null,
  date_of_birth date,
  city text,
  bio text,
  gender text,
  age_min int default 18,
  age_max int default 45,
  distance_max int default 25,
  hide_location boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists photos (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  storage_path text not null,
  is_main boolean default false,
  created_at timestamptz default now()
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  profile_a uuid references profiles(id) on delete cascade,
  profile_b uuid references profiles(id) on delete cascade,
  status text default 'matched',
  created_at timestamptz default now(),
  unique(profile_a, profile_b)
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references matches(id) on delete cascade,
  sender_profile_id uuid references profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

create table if not exists blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_profile_id uuid references profiles(id) on delete cascade,
  blocked_profile_id uuid references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique(blocker_profile_id, blocked_profile_id)
);

create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  reporter_profile_id uuid references profiles(id) on delete cascade,
  reported_profile_id uuid references profiles(id) on delete cascade,
  reason text not null,
  status text default 'pending',
  created_at timestamptz default now()
);

create index if not exists idx_profiles_email on profiles(email);
create index if not exists idx_matches_profile_a on matches(profile_a);
create index if not exists idx_matches_profile_b on matches(profile_b);
create index if not exists idx_reports_status on reports(status);
