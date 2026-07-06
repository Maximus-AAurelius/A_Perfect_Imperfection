# Perfect Imperfection

## Project

Perfect Imperfection is an authenticity-first dating and community platform.

**Core message:** Your imperfections are the point.

**Mission:** Build the most trusted authenticity-first dating platform, not a shallow swipe clone.

---

## How Claude Should Work in This Project

Claude should act as a senior full-stack engineer, product strategist, and safety-conscious architect.

When working on this project, Claude must:

1. Read the existing file structure before making changes.
2. Avoid rewriting the whole project unless specifically requested.
3. Make small, testable changes.
4. Explain what files changed.
5. Explain how to test the change.
6. Protect security, privacy, and user safety.
7. Preserve the brand mission.
8. Keep the MVP focused.
9. Avoid adding unnecessary complexity.
10. Ask only when absolutely blocked.

---

## Project Priorities

The build priority is:

1. Landing page
2. Signup/login
3. Profile setup
4. Photo upload
5. Discovery cards
6. Like/pass system
7. Match system
8. Chat
9. Report/block
10. Admin dashboard
11. Legal/safety pages
12. Payment-ready architecture

Do not jump ahead to future features unless requested.

---

## MVP Scope

The MVP must support:

* User authentication
* Profile creation
* Profile editing
* Photo upload
* Discovery
* Like/pass
* Mutual matching
* Chat between matched users
* Report user
* Block user
* Admin review dashboard
* Safety page
* Community guidelines page

---

## Out of Scope for MVP

Do not build these unless specifically requested:

* AI matching
* Mobile app
* Video profiles
* Community events
* Marketplace
* Local business ads
* Digital gifts
* Full subscription system
* Relationship coaching
* Complex algorithmic recommendations
* Heavy analytics
* Background checks

These may be future features, but not MVP priorities.

---

## Tech Stack

Expected stack:

* Next.js
* React
* Tailwind CSS
* Supabase
* PostgreSQL
* Supabase Auth
* Supabase Storage
* Supabase Realtime
* Vercel
* Stripe (later)

Claude should follow this stack unless specifically instructed otherwise.

---

## Brand Rules

The brand should feel:

* Authentic
* Safe
* Warm
* Human
* Inclusive
* Modern
* Emotionally honest
* Trustworthy

Avoid language that makes users feel broken, defective, ugly, or damaged.

Do not use phrases like:

* Dating for broken people
* Dating for damaged people
* Dating for ugly people
* Dating for defects
* Dating for people nobody wants

Preferred language:

* Real connection starts with honesty.
* Your imperfections are part of your story.
* You do not have to pretend to be perfect.
* You are enough as you are.
* Different is not wrong.
* Your imperfections are the point.

---

## Design Direction

The design should be:

* Clean
* Mobile-first
* Accessible
* Warm
* Modern
* Trust-building
* Not overly corporate
* Not overly childish
* Not overly sexualized

Avoid:

* Dark scammy dating-site design
* Overly polished fake influencer style
* Generic SaaS landing page look
* Aggressive hookup-app energy
* Overly medical or therapy-only branding

---

## Frontend Rules

When building frontend features:

1. Use reusable components.
2. Keep pages clean and mobile responsive.
3. Use clear loading states.
4. Use clear error states.
5. Make report/block actions easy to find.
6. Avoid exposing private user data.
7. Use accessible labels and semantic HTML.
8. Keep landing page copy aligned with the mission.
9. Make safety messaging visible but not fear-based.
10. Do not add fake testimonials unless clearly marked as placeholders.

---

## Backend Rules

When building backend logic:

1. Validate all user inputs.
2. Never trust frontend-only checks.
3. Use Supabase Row Level Security.
4. Keep users from accessing private data.
5. Keep chat limited to matched users.
6. Prevent blocked users from messaging.
7. Prevent duplicate swipes.
8. Create matches only after mutual likes.
9. Keep admin-only actions protected.
10. Log moderation actions where appropriate.

---

## Supabase Rules

Supabase should be used for:

* Auth
* User profiles
* Photos
* Preferences
* Swipes
* Matches
* Messages
* Reports
* Blocks
* Notifications
* Admin users
* Moderation actions

Supabase should not be used for:

* Random project notes
* Brand brainstorming
* Prompt storage
* Planning documents

Those belong in Obsidian or GitHub docs.

---

## Database Tables

Initial tables should include:

* profiles
* photos
* preferences
* swipes
* matches
* messages
* reports
* blocks
* notifications
* subscriptions
* admin_users
* moderation_actions

---

## Row Level Security Requirements

RLS must protect all user data.

Required rules:

* Users can only update their own profile.
* Users can only delete their own photos.
* Users can only upload photos to their own account.
* Users can only swipe as themselves.
* Users can only view their own matches.
* Users can only message within their own matches.
* Users cannot message users who blocked them.
* Users cannot message users they blocked.
* Users can create reports.
* Users can view reports they created if needed.
* Only admins can review all reports.
* Only admins can suspend or ban users.
* Public discovery should only show safe public profile fields.

---

## Authentication Rules

Use Supabase Auth.

Authentication flow should support:

* Signup
* Login
* Logout
* Forgot password
* Email verification if enabled
* Protected routes
* Redirect unauthenticated users to login
* Redirect new users to profile setup

Never expose private auth tokens or service role keys.

---

## Environment Variable Rules

Never commit `.env.local`.

Use `.env.example` for placeholders.

Expected variables may include:

```text
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SITE_URL=
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
```

Rules:

* `NEXT_PUBLIC_` variables may be used in frontend.
* `SUPABASE_SERVICE_ROLE_KEY` must only be used server-side.
* Stripe secret keys must only be used server-side.
* Do not hardcode secrets in code.

---

## Chat Rules

Chat must be safety-first.

Rules:

* Only matched users can chat.
* Blocked users cannot chat.
* Unmatched users cannot continue chatting.
* Messages should be stored in Supabase.
* Realtime updates may use Supabase Realtime.
* Report button should be accessible from chat.
* Block button should be accessible from chat.
* Unsafe messages should be reportable.
* Future moderation may flag messages automatically.

---

## Match Rules

Matching should work like this:

1. User A likes User B.
2. Store the swipe.
3. Check whether User B already liked User A.
4. If yes, create a match.
5. If no, wait.
6. If either user blocks the other, hide/prevent the match.

Do not create duplicate matches.

---

## Discovery Rules

Discovery should:

* Show only active profiles.
* Exclude the current user.
* Exclude blocked users.
* Exclude users who blocked the current user.
* Exclude already-swiped users if appropriate.
* Hide banned/suspended users.
* Avoid exact location exposure.
* Use approximate location or general area only.

---

## Report and Block Rules

Report and block must be available from:

* Profile cards
* User profile pages
* Chat
* Match view

Blocking should:

* Hide the blocked user
* Prevent future chat
* Prevent future discovery appearance
* Hide or disable existing match interaction

Reporting should:

* Store reporter
* Store reported user
* Store reason
* Store optional details
* Set status to pending
* Make report visible in admin dashboard

---

## Admin Dashboard Rules

Admin dashboard should allow authorized admins to:

* View pending reports
* View reported users
* View report history
* Review flagged photos
* Review flagged messages when necessary
* Suspend users
* Ban users
* Remove unsafe content
* Resolve reports
* Add moderation notes

Admin actions should be protected and auditable.

---

## Safety Rules

Safety is a core feature.

The app must support:

* 18+ only requirement
* Community guidelines
* Safety page
* Report/block system
* Admin review
* Ban/suspend tools
* Scam prevention
* Fake profile response
* Harassment response
* Approximate location only

Zero tolerance for:

* Underage users
* Fake profiles
* Harassment
* Hate speech
* Threats
* Scams
* Money requests
* Stalking
* Spam
* Sexual exploitation
* Impersonation
* Ban evasion

---

## Location Safety

Never expose exact user location.

Allowed:

* City
* General area
* Approximate distance
* State/region

Not allowed:

* Street address
* Exact GPS coordinates shown publicly
* Live tracking
* Public map pins on a user's exact location

---

## Payment Rules

Stripe is future-ready, not MVP-critical.

Do not make payment required for core connection features in the MVP.

Future paid features may include:

* Perfect+
* Boosts
* Super Likes
* See who liked you
* Advanced filters
* Read receipts
* Passport
* Verification upgrade

Free users should still be able to:

* Create profile
* Discover users
* Like/pass
* Match
* Chat with matches
* Report/block

---

## Code Change Format

After making changes, Claude should respond with:

1. Summary of what changed
2. Files changed
3. How to test
4. Any environment variables needed
5. Any Supabase/database changes needed
6. Any security notes

Use this format:

```text
Summary:
- ...

Files changed:
- ...

How to test:
1. ...

Environment variables:
- None / list variables

Database changes:
- None / list changes

Security notes:
- ...
```

---

## Testing Checklist

For every completed feature, test:

* Desktop layout
* Mobile layout
* Logged-out state
* Logged-in state
* Loading state
* Error state
* Invalid input
* Permission restrictions
* Supabase RLS behavior
* Report/block behavior if relevant

---

## Git Rules

Use clean commits.

Suggested commit style:

```text
feat: add profile setup page
fix: prevent blocked users from messaging
docs: update safety policy
refactor: simplify auth redirect logic
```

Do not commit:

* `.env.local`
* API keys
* Supabase service role key
* Stripe secret key
* Private user data
* Test user credentials

---

## Documentation Rules

Keep docs updated when major changes happen.

Update relevant docs when changing:

* Database schema
* Auth flow
* Routes
* Supabase setup
* Safety rules
* Admin behavior
* Environment variables
* Deployment process

---

## Obsidian Notes

Planning documents live in Obsidian.

Important Obsidian folders:

* 00_Master Plan
* 01_Brand
* 02_Product
* 03_Engineering
* 04_Safety
* 05_Legal
* 06_Marketing
* 07_Prompts
* 08_Research
* 09_Assets
* 10_Archive

Use Obsidian for project thinking.

Use GitHub for code.

Use Supabase for app data.

---

## Important Instruction

Do not overbuild.

Perfect Imperfection should launch with a clean, safe, usable MVP before adding advanced features.

The first goal is not to build every possible dating app feature.

The first goal is to prove that users can safely:

1. Sign up
2. Create a profile
3. Discover people
4. Match
5. Chat
6. Report/block unsafe users
