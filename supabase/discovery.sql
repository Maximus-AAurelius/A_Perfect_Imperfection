-- ============================================================
-- Perfect Imperfection — Discovery photo read policy
-- Run this in the Supabase SQL Editor AFTER schema.sql + storage_photos.sql.
-- Safe to re-run (idempotent).
--
-- Why: photos_owner_or_admin (in schema.sql) only lets a user read their OWN
-- photo rows. Discovery needs to read the photo rows of OTHER members so it
-- can generate signed URLs for their cards. This adds a SELECT-only policy
-- that mirrors profiles_select_safe: a signed-in member may read a photo row
-- when the owning profile is visible to them (their own, or an active profile
-- that hasn't blocked them / that they haven't blocked). Admins see all.
--
-- RLS permissive policies are OR'd, so this only BROADENS SELECT; it does not
-- affect who can insert/update/delete photos (still owner-only).
-- ============================================================

drop policy if exists photos_select_discoverable on public.photos;
create policy photos_select_discoverable on public.photos
for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = photos.profile_id
      and (
        p.user_id = auth.uid()
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

-- Note: photo-level moderation (only showing 'approved' photos) is intentionally
-- NOT enforced yet — there is no photo review flow in the MVP, so all of a
-- visible profile's photos are shown. Tighten this when moderation ships.
