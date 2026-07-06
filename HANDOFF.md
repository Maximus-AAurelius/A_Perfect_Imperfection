# A Perfect Imperfection - Static Netlify + Supabase MVP Handoff

**Updated:** 2026-07-05
**Canonical target:** root static app (`index.html`) deployed on Netlify
**Domain:** `https://aperfectimperfection.org`

## What Changed This Pass

- Chose the root `index.html` app as the canonical short-term target.
- Removed the duplicated tracked `app/` copy so the repo has one app source of truth.
- Bundled the current deploy into a self-contained `index.html`.
- Removed the Design Component runtime self-fetch from `index.html` to prevent runtime source text from appearing on the live page.
- Replaced the starter Supabase schema with an MVP schema that includes:
  - RLS on all app tables
  - `profiles`, `photos`, `swipes`, `matches`, `messages`, `blocks`, `reports`
  - `admin_users` and `moderation_actions`
  - `create_match_if_mutual(target_profile uuid)` RPC for mutual matching
- Removed the always-visible client Admin link.
- Added a Supabase `admin_users` role check before showing/entering admin.
- Changed forgot-password behavior to call Supabase reset email instead of only setting local UI state.
- Updated docs away from the stale Next.js assumption.

## Current App State

### Working / Partially Wired

- Static landing and prototype UI
- Supabase Auth signup/login
- Profile creation saved to Supabase
- Password reset email request through Supabase
- Admin link hidden unless the signed-in user has a row in `admin_users`

### Still Prototype / Mock

- Discovery still uses the hardcoded `PROFILES` array
- Swipes are still held in browser state
- Matches are still created locally from mock profile flags
- Chat messages are still browser state
- Reports and blocks update local state only
- Admin dashboard still renders mock report/user data
- Photos are still placeholders/local UI state

## Required Supabase Setup

Run:

```sql
-- In Supabase SQL editor
-- Paste and execute supabase/schema.sql
```

Then create an owner/admin row after signing up the admin account:

```sql
insert into public.admin_users (user_id, role)
values ('AUTH_USER_UUID_HERE', 'owner')
on conflict (user_id) do update set role = 'owner';
```

## Next Engineering Steps

1. Add `currentProfileId` loading and use it throughout the UI.
2. Replace `PROFILES` discovery with a Supabase query against safe profile fields.
3. Persist swipes and call `create_match_if_mutual()` for likes/superlikes.
4. Load matches from `matches` and hydrate matched profiles.
5. Persist chat messages in `messages` and subscribe with Supabase Realtime.
6. Persist block/report actions in `blocks` and `reports`.
7. Replace admin mock data with RLS-protected report/moderation queries.
8. Add Supabase Storage for compressed user photos.

## Safety Notes

- Do not broaden real-user testing until `supabase/schema.sql` has been run and RLS has been verified.
- The static client can hide admin UI, but real protection must stay in Supabase RLS and policies.
- Admin actions should be written to `moderation_actions`; never rely only on client state.
- Discovery must exclude blocked users, users who blocked the current user, and suspended/banned profiles.

## Deployment Notes

- For the current deploy, upload only `index.html` to Netlify.
- Keep GoDaddy DNS pointed at the Netlify site for `aperfectimperfection.org`.
- Do not deploy `support.js`, old `.dc.html` files, `assets/`, or the `supabas/` folder unless the app is rebuilt and the deployment approach changes.
