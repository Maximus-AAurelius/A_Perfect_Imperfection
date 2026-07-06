# Claude Design — Handoff

Handoff for continuing **visual/design work** on the Perfect Imperfection landing + app UI in Claude Design.

_Last updated: 2026-07-05 — includes full project audit + next steps._

> **Start here:** The landing page looks good and is done for now. The next work is the **onboarding/profile flow**. Right now you can create a profile, **but you cannot actually add photos, and hitting "Create" at the end appears to do nothing**. See **Project Audit** and **Next Steps** below for exactly why and what to build.

---

## What this project is

**Perfect Imperfection** — an authenticity-first dating & community platform.

- **Core message:** _Your imperfections are the point._
- **Mission:** the most trusted authenticity-first dating platform — not a shallow swipe clone.
- **Live site:** https://aperfectimperfection.org (Netlify hosting, GoDaddy DNS)

---

## Source of truth

| File | Role |
|------|------|
| `index.html` | **The live page.** Single-file Claude Design "Design Component" export (`.dc` style) — all screens, styles, and template bindings in one file. This is what gets deployed. |
| `assets/hero-model-v2.webp` | Hero model photo (right side of the landing hero). 610×1000, 84 KB. |
| `deploy/` | Clean, ready-to-drop copy (`index.html` + `assets/`) for manual Netlify upload. Rebuild it from the root files before each deploy. |
| `Perfect Imperfection.dc.html` (in git history) | The **original** Claude Design export. Deleted from working tree but recoverable via git — useful reference for the intended layout. |

> This is a **Design Component (`.dc.html`) export**, not a hand-authored site. It uses `dc-root` / `sc-host` host classes, multiple `viewportKey` screens (e.g. `dc-model`), and `{{ }}` template placeholders bound to app logic. **Preserve those markers and bindings** when editing — they are how the design connects to Supabase auth and app state.

---

## Brand voice (must-follow)

Feel: authentic · safe · warm · human · inclusive · modern · emotionally honest · trustworthy.

**Never** use language that makes users feel broken, defective, ugly, or damaged. Banned framings: "dating for broken/damaged/ugly people," "for defects," "for people nobody wants."

**Preferred lines:**
- Real connection starts with honesty.
- Your imperfections are part of your story.
- You don't have to pretend to be perfect.
- You are enough as you are.
- Different is not wrong.
- Your imperfections are the point.

---

## Design tokens (pulled from the live file)

**Fonts** (Google Fonts, already linked):
- **Poppins** — headings / CTAs (weights 600, 700, 800)
- **Inter** — body / UI (weights 400, 500, 600, 700)

**Color palette** (OKLCH — the file uses OKLCH throughout, keep it consistent):

| Role | Value | Notes |
|------|-------|-------|
| Brand coral (primary CTA) | `oklch(0.62 0.19 15)` | "Join Free" buttons, primary actions |
| Deep accent red | `oklch(0.55 0.19 25)` | secondary accents, markers |
| Page background (cream) | `oklch(0.98 0.008 60)` | warm off-white base |
| Ink / dark text | `oklch(0.22 0.02 50)` | headings, dark panels |
| Muted text | `oklch(0.5 0.02 50)` | body/secondary copy |
| Hairline / border | `oklch(0.9 0.012 50)` | card + divider borders |
| Soft pink tint | `oklch(0.95 0.03 15)` | icon chips, subtle fills |

---

## Current design state

The page is a full-length landing + app preview. Screens/sections present today:

- **Landing hero** — headline + "Join Free" / "I have an account" CTAs on the left, model photo on the right.
- **How It Works** / trust-building sections.
- **Safety** — "How we protect you," verification, AI + human moderation, approximate-location-only, report/block, "we review every report."
- **Community Guidelines** + enforcement ladder (Warning → Suspension → Permanent ban).
- **Auth flows** — signup, login, "Check your inbox" (Supabase-backed).
- **App preview screens** — Discover, Community, Account/Settings (Filters, Discovery preferences, Hide my location, Export data, Delete account), Admin dashboard.

### Most recent change
The landing hero photo was missing (an earlier cleanup replaced it with an SVG placeholder and deleted the file). **Fixed:** restored the model image and compressed it 1.2 MB PNG → 84 KB WebP (quality 90, visually identical). Hero now references `assets/hero-model-v2.webp`.

---

## Deploy reality (important for design changes)

- **Manual drag-and-drop only.** Netlify is **not** auto-connected to GitHub. A `git push` does **not** update the live site.
- To publish: rebuild the `deploy/` folder (root `index.html` + `assets/`), then drag the **whole `deploy` folder** onto Netlify → Deploys.
- **Relative asset paths matter.** The hero links to `assets/hero-model-v2.webp` relatively. Any new image asset must ship inside the dropped folder at the referenced path, or it 404s. Prefer inlined SVG / data-URIs or keep assets in `assets/`.
- After deploy, hard-refresh (Ctrl+Shift+R) to bypass the Netlify edge cache.

---

## Design guardrails

- **Mobile-first, accessible, warm.** Clean and modern — not corporate SaaS, not hookup-app energy, not scammy dating-site design, not overly medical/therapy.
- Keep **report/block affordances easy to find** on every profile, match, and chat surface.
- **Never expose exact location** in UI — city / approximate distance only.
- Safety messaging should be **visible but not fear-based**.
- No fake testimonials unless clearly marked placeholder.
- Semantic HTML + accessible labels; clear loading and error states.

---

---

## Project Audit (2026-07-05)

**What this really is:** a high-fidelity front-end prototype with **real Supabase Auth**, a **real database schema**, but most app data still **mocked**. Auth works; the layers past it are placeholders or blocked.

### ✅ Working / real
- **Supabase Auth** — signup, login, logout, session, forgot-password all call the real client (`supabaseClient` in `index.html`). Signups DO create `auth.users` rows (confirmed emails are logged in Supabase).
- **Database schema** — `supabase/schema.sql` is comprehensive: `profiles, photos, swipes, matches, messages, blocks, reports, admin_users, moderation_actions`, all with RLS enabled and per-user policies. This is solid.
- **Landing page + hero** — done and looks good.

### ✅ Fixed on 2026-07-05 (was broken)
1. **Email-confirm/session gap → profile now saves.** Email confirmation was turned OFF in Supabase, so signup returns a live session and the `profiles` upsert succeeds under RLS. Verified end-to-end (profile creates all the way through). The upsert now also writes `interests`.
2. **Confirm-password field added** to the signup form (signup mode only). Blocks submit if the two passwords don't match or the password is under 6 chars.
3. **Real photo upload built** (replaces the old fake toggle):
   - Onboarding photo step now has a **real file picker** (JPG/PNG/WebP, max 5 MB), uploads to a **private** Supabase Storage bucket `profile-photos/<uid>/…`, shows the image via a **short-lived signed URL**, and enforces **max 3** photos (frontend + DB trigger).
   - On "Create," photos are written to the `photos` table linked to the new profile row.
   - **Requires running `supabase/storage_photos.sql` once** in the Supabase SQL editor (creates the bucket, storage RLS, and the 3-photo limit trigger).

### ✅ Also done 2026-07-06 — real Discovery + swipe loop
- **Login now loads your real profile + photos** from Supabase (account screen shows real data; if a signed-in user has no profile yet they're routed to onboarding).
- **Discovery reads real profiles** from Supabase (active, not-blocked, not-yet-swiped, excludes self), showing each person's real main photo via a signed URL, with age computed from date of birth.
- **Pass** writes a `swipes` row; **Like/Superlike** call the `create_match_if_mutual` RPC — a mutual like creates a `matches` row and pops the "It's a Match!" modal.
- **Requires running `supabase/discovery.sql` once** (adds a SELECT policy so members can read other discoverable profiles' photo rows).
- **To see it work you need ≥2 accounts** with photos (discovery excludes yourself).

### ✅ Also done 2026-07-06 — real Matches, Chat, Report/Block
- **Matches tab loads real matches** from Supabase (other person's name + photo + last-message preview).
- **Chat is real**: opens a match → loads `messages` → send inserts a row → **Supabase Realtime** streams the other person's messages live.
- **"Send a message"** on the match modal now opens the real chat.
- **Report / Block / Unmatch are persisted**: block inserts a `blocks` row (and unmatches via the `unmatch` RPC); report inserts a `reports` row (+ blocks); unmatch calls the RPC. Blocking removes the person from discovery and matches, and messaging is blocked server-side by RLS.
- **Requires running `supabase/chat.sql` once** (enables Realtime on `messages` + adds the participant `unmatch()` RPC).

### ⚠️ Still mocked / follow-ups (next up)
1. **Admin dashboard** is still mock (reads `PROFILES` + fake reports). The admin nav link is still visible to everyone — **hide it / gate it to real admins** (flagged for the security pass).
2. **Superlike** is recorded as a normal `like` (the RPC hardcodes 'like').
3. **Settings → Blocked users** list shows "Unknown" for real blocks (no names stored locally).
4. **Cross-user photo viewing** works via signed URLs readable by any signed-in member (private to non-members). Future hardening: sign URLs server-side via an Edge Function scoped to approved photos of active, non-blocked profiles.
5. **Pending: full security review** (RLS coverage, admin gating, input validation, secret exposure) — planned next.

### 🧹 Housekeeping
- Stray **`supabas/`** folder (typo of `supabase/`) contains an old duplicate `index.html` + `.dc.html` + assets. It's gitignored but still clutters the working tree — safe to delete.

---

## Next Steps (in order)

0. **RUN THESE SQL FILES ONCE (in order):** `storage_photos.sql` (done), `discovery.sql`, **and now `chat.sql`** (Realtime on messages + the `unmatch()` RPC). Chat/unmatch won't work until `chat.sql` is run.
1. **Full security review** (next, per request) — RLS coverage on every table, gate the admin dashboard to real `admin_users`, hide the admin nav link, validate inputs, confirm no secret/service-role exposure, check the anon key is the only key in the client.
2. **Admin dashboard on real data** — real reports queue, suspend/ban actions via admin-only RLS.
3. **Account-screen photo editing** — persist add/remove/set-main against the `photos` table for an existing profile (onboarding already persists).
4. **Design polish alongside the above** — loading/empty/error states for auth, onboarding, discovery, and chat in the warm brand voice.

## Design tasks you may want in Claude Design
- Onboarding photo step: the slots now show real uploaded images. Consider a nicer empty-slot affordance, an upload progress treatment, and a clear "main photo" indicator.
- Signup form now has a **Confirm password** field (signup only) — style it consistently with the other inputs.

## Risks / gotchas

- It's a **single-file design export** — keep it portable; don't split into external CSS/JS that the drag-drop deploy won't carry.
- Don't break `{{ }}` template bindings or `dc-`/`sc-` host markers — they wire the design to Supabase auth/app logic.
- **RLS + session:** any write to Supabase needs a real authenticated session (JWT), or RLS will silently reject it. The current signup gap is the #1 blocker.
- Watch total page weight; inline everything else but keep raster images compressed (WebP).
- The live edge caches HTML — always hard-refresh to confirm a change actually shipped.
- Deploy is manual drag-drop of the `deploy/` folder — a `git push` does NOT update the live site.
