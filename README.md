# A Perfect Imperfection

Authenticity-first dating and community platform.

**Core message:** Your imperfections are the point.

## Canonical App Target

The current canonical web app is the self-contained root static deploy file:

- `index.html` - main app shell deployed as the landing/MVP experience
- `supabase/schema.sql` - database, RLS, matching, messaging, reports, blocks, and moderation schema

The site is intended to deploy as a static app on Netlify. The public domain is:

- `https://aperfectimperfection.org`

The old duplicated `app/` copy has been removed so the root files are the source of truth.

## Current Status

- Brand direction established
- Safety and moderation direction established
- Static landing/prototype deployed through Netlify
- Supabase Auth and profile saving are wired in the static app
- Supabase MVP schema now includes RLS, swipes, matches, messages, blocks, reports, admin users, and moderation actions
- Discovery, matches, chat, reports, blocks, and photos still need to be fully connected from the static UI to Supabase data

## Run Locally

Open `index.html` in a browser, or serve the folder with any static server.

Example:

```bash
npx serve .
```

The app needs internet access for Supabase and CDN-hosted client libraries.

## Deploy

For the current Netlify deploy, upload only `index.html`.

Do not upload `support.js`, old `.dc.html` files, `assets/`, or the `supabas/` folder unless the app is rebuilt and the deployment approach changes.

DNS is connected through GoDaddy for `aperfectimperfection.org`.

## Supabase

Before broader testing with real users:

1. Run `supabase/schema.sql` in the Supabase SQL editor.
2. Create at least one owner/admin row in `admin_users` for the real admin account.
3. Confirm RLS is enabled on all app tables.
4. Test regular-user access cannot read or update other users' private data.

## MVP Priorities

1. Load real discovery profiles from Supabase.
2. Persist swipes and create matches only through `create_match_if_mutual`.
3. Persist messages in `messages`.
4. Persist reports and blocks.
5. Replace mock admin rows with `reports`, `profiles`, and `moderation_actions`.
6. Wire photo upload to Supabase Storage.

## Important Files

- `CLAUDE.md` - project rules and product/safety guidance
- `HANDOFF.md` - current implementation handoff
- `Safety & Moderation Policy.md` - safety copy and moderation policy
- `FREE_TIER_PLAN.md` - private MVP rollout notes
- `supabase/schema.sql` - database schema and RLS
