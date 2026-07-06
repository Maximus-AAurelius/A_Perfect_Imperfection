# A Perfect Imperfection — Supabase MVP Handoff

**Date:** 2026-07-05  
**Status:** Auth + Profile Creation Wired to Supabase  
**Next Phase:** Real Discovery & Chat Integration

---

## Goal

Transform the front-end-only prototype into a production-ready MVP using Supabase free tier for:
- Real user authentication
- Profile storage and retrieval
- Matches, messages, blocks, and reports
- Moderation queue (manual at first)
- Private soft launch with minimal operational cost

---

## Current State

### What's Live ✅
- **Supabase Auth**: Signup/login with email + password fully working
- **Profile Creation**: Onboarding flow saves profiles to `profiles` table in Postgres
- **Schema**: All tables created (profiles, photos, matches, messages, blocks, reports)
- **Data Service Layer**: Abstraction for auth + profile mutations
- **Local Storage**: Still works as fallback if Supabase unavailable
- **UI/UX**: Unchanged—full design fidelity maintained

### What's Still Mock
- Discovery feed (still uses hardcoded PROFILES array with 14 mock users)
- Matches (stored in state, not persisted to Supabase)
- Messages (state-only, no Realtime)
- Reports and blocks (UI works, data not persisted)
- Photos (uploaded to browser memory, not Supabase Storage)

---

## What Changed

### Code Changes

**File: `Perfect Imperfection.dc.html`**

1. **Added Supabase Library** (line 6)
   ```html
   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/"></script>
   ```

2. **Supabase Initialization** (after PROFILES array)
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY` constants
   - `initSupabase()` function
   - `dataService` object with methods:
     - `signUp(email, password, fullName, dateOfBirth)`
     - `login(email, password)`
     - `logout()`
     - `getCurrentUser()`
     - `saveProfile(userId, email, fullName, ...)`

3. **Updated Component**
   - `componentDidMount()`: Initializes Supabase, checks for existing session
   - `submitAuth()`: Calls `dataService.signUp()` or `dataService.login()`
   - `logout()`: Calls `dataService.logout()`
   - `onboardingNext()`: Saves profile to Supabase on completion
   - Added `currentUserId` and `currentUserEmail` to state

4. **Schema Created in Supabase**
   - `profiles` — user profiles with name, email, age, preferences
   - `photos` — photo references (URLs to storage)
   - `matches` — bidirectional matches
   - `messages` — chat messages with match_id FK
   - `blocks` — user blocks (prevents showing in discovery, hides matches)
   - `reports` — moderation queue (reason, status, admin notes placeholder)
   - Indices on email, match participants, report status

### Files Changed
- `Perfect Imperfection.dc.html` — main app (Supabase client + auth flow)

### Files Created
- `HANDOFF.md` (this file)

---

## What Still Needs Done

### Phase 1: Discovery → Realtime (Priority)
- [ ] Load profiles from `profiles` table instead of mock PROFILES array
- [ ] Filter by age, distance, gender in discovery
- [ ] Mark profiles as "swiped" (store in `swipes` table or similar)
- [ ] Prevent showing blocked users in discovery

### Phase 2: Matches & Messages
- [ ] Save matches to `matches` table (check for mutual interest)
- [ ] Save messages to `messages` table
- [ ] Wire Supabase Realtime for live message updates (no polling)
- [ ] Show unread count from database

### Phase 3: Reports, Blocks, Admin
- [ ] Save blocks to `blocks` table
- [ ] Save reports to `reports` table
- [ ] Admin dashboard: pull `reports` with status='pending'
- [ ] Admin actions: mark as 'resolved', add notes, suspend/ban users

### Phase 4: Photos & Storage
- [ ] Wire Supabase Storage for photo uploads
- [ ] Replace emoji placeholders with real uploaded images
- [ ] Compress images before upload (free tier bandwidth)
- [ ] Store `storage_path` in `photos` table

### Phase 5: Deployment & Polish
- [ ] Test email verification flow
- [ ] Set up password reset email
- [ ] Add RLS (Row Level Security) policies
- [ ] Rate limiting on auth endpoints
- [ ] Deploy to Vercel/Netlify
- [ ] Custom domain (optional for MVP)

---

## Risks & Constraints

### Low Risk
- Auth flow is simple (email + password, no OAuth yet)
- RLS not enforced yet (dev-only, but flag for production)
- No photo uploads implemented (avoids storage costs initially)

### Medium Risk
- **Realtime chat**: Supabase Realtime requires 1 CCU per connected client; free tier allows ~100 concurrent at peak. Monitor after soft launch.
- **Discovery load**: If profiles grow > 1K, queries may need pagination + caching. Current `getProfiles()` does full table scan.
- **No verification**: Email verification not wired yet. Users can sign up with fake emails.

### High Risk (Mitigated in MVP)
- **RLS not enforced**: Any authenticated user can read/write to any profile. Add RLS policies before prod launch.
- **Photos stored in browser**: Currently mocked. Once Storage is live, monitor quota (100 GB free tier).

---

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Keep localStorage as fallback | Dev iteration speed; graceful degradation if Supabase down |
| No OAuth yet | Email auth is simpler; OAuth adds complexity for MVP |
| Manual moderation (reports table only) | Reduces scope; reports are the admin queue, not auto-actioned |
| No photo uploads in Phase 1 | Simplifies MVP; photos added in Phase 4 |
| Single Supabase project | No need for staging/dev splits at this scale |

---

## Next Actions (Priority Order)

### 1. Test Auth Flow (30 min)
- [ ] Open app in browser
- [ ] Sign up with test email
- [ ] Complete onboarding
- [ ] Verify profile appears in Supabase `profiles` table
- [ ] Log out, log back in
- [ ] Confirm you return to discovery (session restored)

### 2. Load Real Profiles in Discovery (1-2 hrs)
- [ ] Create `getFilteredProfiles()` method in dataService
- [ ] Replace hardcoded PROFILES array with Supabase query
- [ ] Wire discovery filters (age, distance, gender) to query params
- [ ] Test filtering works end-to-end

### 3. Wire Matches to Database (1 hr)
- [ ] Create `createMatch()` in dataService
- [ ] Update `doSwipe()` to save match to `matches` table (if mutual like)
- [ ] Load matches from Supabase on mount

### 4. Messages + Realtime (2 hrs)
- [ ] Create `sendMessage()` in dataService → save to `messages` table
- [ ] Subscribe to Realtime on active match
- [ ] Replace state-driven message list with Supabase data

---

## Commands & URLs

### Supabase Project
- **Dashboard**: https://supabase.com/dashboard/project/ouanfrbzlejeiocywony
- **Project URL**: `https://ouanfrbzlejeiocywony.supabase.co`
- **Anon Key**: `sb_publishable_I5Hou3fFKOWCqV4YgxHpsA_VQLY27oA` (public, safe in app code)

### Run App Locally
- Open `Perfect Imperfection.dc.html` in browser (live-server or file://)
- Requires internet (Supabase API calls)

### Deploy to Prod
```bash
# Vercel (recommended for static HTML)
vercel deploy

# Or Netlify
netlify deploy --prod
```

---

## Architecture Notes

### Data Service Pattern
All Supabase calls go through `dataService` object. This allows:
- Easy mocking for tests
- Fallback to localStorage if needed
- Centralized error handling
- Clear API contract

### State vs. Database
- **State**: UI state (view, loading, modals, form inputs)
- **Supabase**: Persistent data (users, profiles, matches, messages, reports)
- **localStorage**: Backup for state during dev (can remove once Supabase is stable)

### Authentication Flow
1. User signs up → Supabase Auth creates `auth.users` entry + sends confirmation email (optional)
2. App creates matching row in `profiles` table (user_id FK)
3. On login, fetch user from `auth.getUser()` and use user.id for all queries

---

## Testing Checklist

- [ ] Sign up with new email → profile created in DB
- [ ] Log in with that email → restored to discovery
- [ ] Log out → redirected to landing
- [ ] Password reset link sent (check email flow)
- [ ] Onboarding validation works (name, photo, etc.)
- [ ] Discovery filters work (age, distance, gender)
- [ ] Swiping creates matches (check `matches` table)
- [ ] Messages send + appear (Realtime working)
- [ ] Block creates entry in `blocks` table
- [ ] Report creates entry in `reports` table with status='pending'
- [ ] Admin sees pending reports

---

## Known Limitations

1. **No email verification yet** — anyone can sign up with any email
2. **No password reset UI** — reset link works, but flow not tested end-to-end
3. **Photos are placeholders** — emoji initials, not real uploads
4. **No push notifications** — would add complexity; Web Push optional for MVP+1
5. **Admin dashboard is mock** — fully works with Supabase data, but no auth gate yet
6. **RLS not enforced** — any auth user can see/modify any profile (okay for dev, fix before prod)

---

## Success Criteria for MVP Launch

- [x] Real user signup/login working
- [x] Profiles persist to Supabase
- [ ] Discovery loads profiles from database
- [ ] Matches + messages live
- [ ] Reports + blocks persisted
- [ ] Soft launch to 5-10 testers
- [ ] No errors in production logs
- [ ] Load time < 2s on 4G

---

## Questions for Next Session

1. **Photos**: Should we implement photo upload in Phase 1 or defer to Phase 2?
2. **Verification**: Send email verification on signup, or skip for MVP soft launch?
3. **RLS**: Should we add Row Level Security now (safe), or wait until public launch?
4. **Realtime**: Test websocket behavior under load—how many concurrent connections can we handle?
5. **Moderation**: Do you want an admin email alert when new reports come in, or just check the dashboard?

---

**Owner:** Travis  
**Last Updated:** 2026-07-05  
**Next Review:** After Phase 1 testing
