-- ============================================================
-- Perfect Imperfection — fix "permission denied for table" on photos
-- Run in the Supabase SQL Editor AFTER: schema.sql, storage_photos.sql,
-- discovery.sql, chat.sql, updates_2026-07-15.sql. Safe to re-run.
--
-- Root cause: schema.sql's hardening tail restricts public.profiles to a
-- column-safe SELECT grant for `authenticated` that excludes `user_id`
-- (intentional — stops other users from reading the auth-user link).
-- But three RLS policies still compared `p.user_id = auth.uid()` directly,
-- which requires SELECT on that column. Postgres checks column privileges
-- while evaluating a policy expression even when another OR'd branch would
-- otherwise allow the row, so any query touching photos/the storage bucket
-- failed with a permission error instead of a normal RLS row-filter result.
--
-- Fix: replace the raw column comparison with public.my_profile_id(), the
-- existing SECURITY DEFINER helper already used elsewhere for this exact
-- purpose. Same result, no column grant needed, user_id stays hidden.
-- ============================================================

-- 1) Your own photo rows (schema.sql) ---------------------------------------
drop policy if exists photos_owner_or_admin on public.photos;
create policy photos_owner_or_admin on public.photos
for all to authenticated
using (
  public.is_admin()
  or exists (select 1 from public.profiles p where p.id = photos.profile_id and p.id = public.my_profile_id())
)
with check (
  public.is_admin()
  or exists (select 1 from public.profiles p where p.id = photos.profile_id and p.id = public.my_profile_id())
);

-- 2) Other members' photo rows for discovery (discovery.sql) ----------------
drop policy if exists photos_select_discoverable on public.photos;
create policy photos_select_discoverable on public.photos
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = photos.profile_id
      and (
        p.id = public.my_profile_id()
        or public.is_admin()
        or (
          p.moderation_status = 'active'
          and not exists (
            select 1 from public.blocks b
            where (b.blocker_profile_id = public.my_profile_id() and b.blocked_profile_id = p.id)
               or (b.blocker_profile_id = p.id and b.blocked_profile_id = public.my_profile_id())
          )
        )
      )
  )
);

-- 3) Storage bucket read policy behind createSignedUrl (storage_photos.sql) -
drop policy if exists "profile_photos_select_authenticated" on storage.objects;
create policy "profile_photos_select_authenticated"
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.photos ph
      join public.profiles p on p.id = ph.profile_id
      where ph.storage_path = storage.objects.name
        and (
          public.is_admin()
          or p.id = public.my_profile_id()
          or (
            p.moderation_status = 'active'
            and not exists (
              select 1 from public.blocks b
              where (b.blocker_profile_id = public.my_profile_id() and b.blocked_profile_id = p.id)
                 or (b.blocker_profile_id = p.id and b.blocked_profile_id = public.my_profile_id())
            )
          )
        )
    )
  )
);

-- 4) Same bug on profiles' own SELECT policy (schema.sql) -------------------
-- Hit by any direct `.from('profiles').select(...)` call (e.g. looking up a
-- match's name for chat) — same fix, same reasoning.
drop policy if exists profiles_select_safe on public.profiles;
create policy profiles_select_safe on public.profiles
for select to authenticated
using (
  public.is_admin()
  or id = public.my_profile_id()
  or (
    moderation_status = 'active'
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_profile_id = public.my_profile_id() and b.blocked_profile_id = profiles.id)
         or (b.blocker_profile_id = profiles.id and b.blocked_profile_id = public.my_profile_id())
    )
  )
);
