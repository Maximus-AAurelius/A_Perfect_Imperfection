# Security audit — 2026-07-14

Scope: root/deploy static application, browser state and authentication flow, Supabase schema/RLS/storage SQL, dependency delivery, Netlify configuration, and legal-consent presentation. This is a source review, not a penetration test of the live Supabase or Netlify accounts because those connectors were unavailable in the session.

## Remediated in the workspace

- Removed broad client mutation privileges from sensitive profile, photo, match, admin, and moderation tables.
- Explicitly revoked default `PUBLIC` execution on security-definer functions and granted only required authenticated calls.
- Replaced discovery access to exact birth dates and Supabase auth user IDs with a narrow RPC returning calculated age.
- Added a caller-only profile RPC for private profile loading.
- Added server-side 18+ validation, profile/report length bounds, distance/range validation, and interest limits.
- Prevented profile owners from changing moderation or verification fields through direct table writes.
- Validated that attached photo paths begin with the signed-in user's UUID and capped attachment count.
- Added database and storage MIME/size constraints for JPEG, PNG, and WebP uploads.
- Added explicit agreement acceptance, version markers, and an append-only legal-acceptance table.
- Prevented ordinary logins from being recorded as acceptance unless the account carries the current signup acceptance metadata.
- Increased new-account password minimum from 6 to 12 characters and removed the prefilled birth date.
- Preserved the verified signup birth date across email-confirmation and returning-user onboarding flows.
- Prevented inactive profiles from creating matches through direct RPC calls and made unmatching clear both prior likes so rematching requires fresh mutual interest.
- Rejected empty/whitespace-only messages at the database boundary and removed public execution from the chat and storage trigger functions.
- Pinned the Supabase browser SDK to an exact version.
- Added Netlify headers for clickjacking, MIME sniffing, referrer leakage, browser permissions, cross-origin isolation, and CSP.
- Kept root and deploy application copies byte-identical and verified their embedded JavaScript parses.

## Release blockers / residual risk

- Apply `supabase/schema.sql`, then `supabase/storage_photos.sql`, `supabase/discovery.sql`, and `supabase/chat.sql` to the live project and test with two ordinary accounts plus one admin. The new client calls RPCs that do not exist until migration.
- Fill every bracketed field in `deploy/terms.html` and obtain licensed legal review. Do not collect agreement acceptance while placeholders remain.
- The home-page agreement link now points to the draft, but signup must remain closed until those placeholders are replaced.
- The generated design-component runtime uses `new Function` and inline script/style, forcing CSP to permit `unsafe-eval` and `unsafe-inline`. A production rebuild into static, locally bundled JavaScript/CSS is needed to remove those allowances and CDN supply-chain exposure.
- The admin dashboard and moderation buttons remain prototype/mock UI. Do not represent that all reports are actively reviewed until the dashboard and an operational response process exist.
- Confirm Supabase Auth settings: email confirmation on, leaked-password protection on, CAPTCHA/rate limits configured, only production/local redirect URLs allowed, short OTP expiry, refresh-token reuse detection, and MFA required for admins.
- Confirm Netlify account MFA, least-privilege team access, deploy notifications, locked production deploys, and domain/DNS ownership protections.
- Run live authorization tests proving ordinary users cannot query email, exact birth date, other users' legal acceptances, admin tables, blocked profiles/photos, or unmatched messages.
- Add automated dependency scanning, secret scanning, backup/restore tests, incident response, retention schedules, abuse staffing, and monitoring before a public launch.
- The repo has no package manifest, automated browser tests, Supabase CLI configuration, or Dockerfile. Local verification is therefore limited to static JavaScript parsing, file consistency, and serving both deploy pages; add a testable build/migration workflow before release.

## Deployment decision

Do not deploy this revision until the Supabase migration and legal placeholders are completed. Deploying the updated client first would break profile/discovery calls; deploying the agreement with placeholders would undermine assent and legal credibility.
