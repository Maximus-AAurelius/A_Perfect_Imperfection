# Free-tier rollout plan

## What is live now
- The prototype now saves profile, match, chat, and settings state locally in the browser.
- There is a visible banner explaining that this is a free-tier starter and that Supabase can be added later.
- Data can be exported to JSON and imported back later.

## Next free-tier steps
1. Create a Supabase project.
2. Run the schema in [supabase/schema.sql](supabase/schema.sql).
3. Enable Supabase Auth and storage.
4. Replace the in-memory mock state with Supabase queries and mutations.
5. Keep moderation manual in the first version and use the reports table as the queue.

## Suggested first launch scope
- Sign up / login with Supabase Auth
- Profiles and photos stored in Supabase storage
- Matches and messages in Postgres with Realtime
- Reports and blocks persisted in Postgres
- Admin queue backed by the reports table

## Cost
- Supabase free tier is enough for an MVP and private soft launch.
- Storage and bandwidth should stay low enough for the first release if photos are compressed.
