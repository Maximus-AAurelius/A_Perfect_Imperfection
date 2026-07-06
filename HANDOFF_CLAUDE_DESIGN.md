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

### ⚠️ Broken / mocked (this is the next work)
1. **Photo upload is 100% fake.** `togglePhotoSlot()` just flips a boolean after a fake 900ms timer and *deliberately fails every 3rd try* to look realistic. There is **no file picker, no image, no `storage.upload`**. The `photos` table + `storage_path` exist in the schema, but **no Supabase Storage bucket is created and nothing is ever uploaded.** → _"cannot add photos."_
2. **"Create" at the end silently fails to persist.** The final step calls `dataService.saveProfile()` (a real `profiles` upsert), but:
   - If **email confirmation is ON** in Supabase, `signUp` returns a user with **no active session (no JWT)**. The upsert then runs as the `anon` role, and RLS policy `profiles_insert_own` (`auth.uid() = user_id`) **rejects it**. The error is caught and shown as a small inline message, so it looks like *"nothing happened."*
   - The upsert also **drops `interests` and all photos** (they're never written), even on success.
   - → _"hit Create and nothing."_ **Root cause is the email-confirm / no-session gap + RLS, not the button.**
3. **Discovery, matches, chat, reports, admin** are all driven by a hardcoded `PROFILES` mock array — **not** reading from Supabase.

### 🧹 Housekeeping
- Stray **`supabas/`** folder (typo of `supabase/`) contains an old duplicate `index.html` + `.dc.html` + assets. It's gitignored but still clutters the working tree — safe to delete.

---

## Next Steps (in order)

1. **Decide the email-confirmation strategy** (this unblocks profile creation):
   - Easiest for testing: **turn OFF email confirmation** in Supabase Auth settings so signup returns a live session and the profile upsert succeeds under RLS. _(We may need to re-test the email/logging flow — that was verified at an earlier testing stage.)_
   - Or keep confirmation ON and save the profile **after** the user confirms + logs in (deferred profile write).
2. **Make the profile "Create" actually persist everything** — include `interests`, and confirm the row lands in `profiles` (check the Supabase table, not just the toast).
3. **Build real photo upload** — add a file input, upload to a Supabase **Storage bucket** (e.g. `profile-photos`), insert rows into the `photos` table with `storage_path`, and enforce owner-only RLS on the bucket.
4. **Wire Discovery to real data** — replace the `PROFILES` mock with `dataService.getProfiles()` reads, honoring block/exclusion rules.
5. **Design polish alongside the above** — loading/empty/error states for auth, onboarding, and discovery in the warm brand voice; mobile rhythm on the onboarding steps.

## Risks / gotchas

- It's a **single-file design export** — keep it portable; don't split into external CSS/JS that the drag-drop deploy won't carry.
- Don't break `{{ }}` template bindings or `dc-`/`sc-` host markers — they wire the design to Supabase auth/app logic.
- **RLS + session:** any write to Supabase needs a real authenticated session (JWT), or RLS will silently reject it. The current signup gap is the #1 blocker.
- Watch total page weight; inline everything else but keep raster images compressed (WebP).
- The live edge caches HTML — always hard-refresh to confirm a change actually shipped.
- Deploy is manual drag-drop of the `deploy/` folder — a `git push` does NOT update the live site.
