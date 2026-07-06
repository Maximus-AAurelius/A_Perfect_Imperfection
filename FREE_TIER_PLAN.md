# Free-Tier Rollout Plan

## Canonical Deployment

The short-term MVP target is the static root app deployed to Netlify:

- App file: `Perfect Imperfection.dc.html`
- Runtime: `support.js`
- Domain: `https://aperfectimperfection.org`
- DNS: GoDaddy -> Netlify

## What Is Live Now

- Static landing/prototype experience
- Supabase Auth for signup/login
- Supabase profile saving during onboarding
- Supabase password reset email request
- Admin link gated by `admin_users`
- Local browser fallback/state for unfinished prototype flows

## Before Real-User Testing

1. Run `supabase/schema.sql`.
2. Create the first owner in `admin_users`.
3. Verify RLS with a regular test account.
4. Confirm regular users cannot enter admin or update another user's rows.
5. Confirm reports, blocks, messages, and swipes are persisted before treating them as real safety controls.

## Next Free-Tier Steps

1. Load discovery profiles from Supabase.
2. Persist swipes and mutual matches.
3. Persist messages and add Realtime.
4. Persist reports and blocks.
5. Replace mock admin rows with Supabase moderation data.
6. Add Supabase Storage photo uploads with client-side compression.

## Cost

Supabase and Netlify free tiers should be enough for a private MVP and small tester group if photos are compressed and Realtime usage is watched.
