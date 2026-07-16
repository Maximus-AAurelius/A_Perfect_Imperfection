-- ============================================================
-- Perfect Imperfection — Profile photo storage + limits
-- Run this in the Supabase SQL Editor AFTER schema.sql.
-- Safe to re-run (idempotent).
--
-- Model: PRIVATE bucket. Photos are never public on the internet.
--   - A user can upload / update / delete only files in their own
--     folder:  profile-photos/<auth.uid()>/<file>
--   - Any signed-in member can READ (so discovery can generate
--     short-lived signed URLs to display other members' photos).
--     Non-members cannot see anything.
--   - Free accounts are capped at 3 photos per profile (DB-enforced).
-- ============================================================

-- 1) Create the private bucket ------------------------------------------------
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', false)
on conflict (id) do update set public = false;

update storage.buckets
set file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp']
where id = 'profile-photos';

-- 2) Storage RLS policies on storage.objects ----------------------------------
-- (storage.foldername(name))[1] is the first path segment = the owner's uid.

drop policy if exists "profile_photos_insert_own" on storage.objects;
create policy "profile_photos_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "profile_photos_update_own" on storage.objects;
create policy "profile_photos_update_own"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "profile_photos_delete_own" on storage.objects;
create policy "profile_photos_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Read: users can read their own folder, and can read objects that belong to
-- profiles visible under the app's block/moderation rules. This lets discovery
-- mint signed URLs without making every bucket object readable to every member.
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
          or p.user_id = auth.uid()
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

-- 3) Enforce the free-tier 3-photo limit on the photos table ------------------
create or replace function public.enforce_photo_limit()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (select count(*) from public.photos where profile_id = new.profile_id) >= 3 then
    raise exception 'Photo limit reached: free accounts can have up to 3 photos.'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_photo_limit() from public, anon, authenticated;

drop trigger if exists trg_photos_limit on public.photos;
create trigger trg_photos_limit
before insert on public.photos
for each row execute function public.enforce_photo_limit();

-- Note: the public.photos table and its owner-or-admin RLS policy
-- (photos_owner_or_admin) already exist in schema.sql — nothing to change there.
