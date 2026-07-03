# A Perfect Imperfection — Safety & Moderation Policy
Reference spec for engineering, trust & safety, and support. Tone in-product: warm but firm — safety is a core feature, not a legal footnote.

---

## 1. Public Safety Page (copy)

**Hero**
> Your safety comes first.
> A Perfect Imperfection is built on real people and real connections — which means safety has to be built in from day one, not bolted on after. Here's exactly how we protect you, and what we need from you in return.

**How we protect you**
- **Verification.** Photo verification, email/phone verification, and device fingerprinting help us catch fake accounts before they reach you. *(placeholder — rolling out post-MVP)*
- **AI + human moderation.** Messages and photos are screened for abuse, scams, and exploitation. Anything flagged is reviewed by our safety team. *(placeholder — rolling out post-MVP)*
- **Approximate location only.** We never show your exact address or pinpoint location — only your city and an approximate distance to other members.
- **Report and block, anywhere.** Every profile, match, and conversation has a report and block option in two taps.
- **We review every report.** Reported content is preserved and reviewed by a human. We don't just take your word for it and we don't just take theirs — we look at the evidence.

**Never do this — on A Perfect Imperfection or anywhere else**
Nobody legitimate will ever ask you for these. If someone does, stop responding and report them immediately.
- Send money, gift cards, cryptocurrency, or banking details
- Share passwords, one-time codes, or account credentials
- Send private or intimate photos to someone you haven't met
- Share your home address, workplace, or other identifying details before you're ready
- Feel pressured to move the conversation to another app immediately, or to meet before you're comfortable

**Meeting in person**
- Video chat before you meet.
- Meet the first time in a public place.
- Tell a friend where you're going and share your match's profile with them.
- Arrange your own transportation.
- Trust your gut — if something feels wrong, it's okay to leave.

**In an emergency**
If you are ever in immediate danger, contact local emergency services first. Use in-app reporting for everything else — our safety team reviews every report.

---

## 2. Community Guidelines (page copy)

**Who can join**
You must be 18 or older. One authentic profile per person — no duplicate, fake, or impersonation accounts.

**Zero tolerance.** These result in immediate content removal and account action, up to a permanent ban on the first offense:
1. Harassment, threats, or intimidation
2. Hate speech or discrimination of any kind
3. Scams, phishing, or requests for money, crypto, gift cards, or financial/banking details
4. Fake profiles, impersonation, or catfishing
5. Sexual exploitation or content involving minors — reported immediately to law enforcement
6. Non-consensual sexual content or sharing someone's images without consent
7. Stalking, unwanted persistent contact, or pressuring someone after they've said no
8. Spam, solicitation, or commercial promotion

**How enforcement works**
- **Warning** — for first-time, lower-severity issues (e.g. an inappropriate but non-threatening comment).
- **Suspension** — temporary loss of access while we investigate or as a cooling-off period.
- **Permanent ban** — for repeat violations or anything in the zero-tolerance list above. No appeal for exploitation or threats-of-harm cases.
- Severe cases (exploitation of minors, credible threats of violence) are escalated to law enforcement immediately and are not subject to the standard warning path.

**Appeals**
If you believe your account was actioned in error, you'll be able to request a review. *(placeholder — appeals flow post-MVP)*

---

## 3. Report / Block UI copy (as implemented)

**Entry points:** every profile card, every match row, every chat header has a Report and a Block action.

**Report modal**
- Title: "Report {name}"
- Body: "Reports are reviewed by our safety team. This also blocks them from seeing your profile."
- Reasons offered: Inappropriate photos · Harassment or abuse · Fake profile / scam · Asked for money or financial info · Underage user · Other
- Footer safety line: "Never send money, crypto, gift cards, passwords, or private photos to someone you haven't met."
- Submit button: "Submit & block" — submitting a report always blocks the user; it is not a separate step.

**Block (without reporting)**
- Confirmation copy: "Block {name}? They won't be able to see your profile, match with you, or message you again. They won't be notified."

**Persistent reminders**
- Discovery feed footer: "Never share financial info or personal details before you've met. Report anything that feels off."
- Chat header, first message in a new match: "You just matched — remember, never send money or personal info to someone you haven't met in person."

---

## 4. Admin Moderation Rules

**Queue triage**
1. All reports land in the Reports queue with status `pending`, sorted newest first.
2. Zero-tolerance categories (exploitation, threats, underage) are flagged and surfaced at the top regardless of report age.
3. Reported content (photo, message thread, profile snapshot) is preserved and attached to the report — never deleted on report, only on resolution + retention window expiry.

**Available actions per report/user**
- **Warn** — sends a policy-reminder notice to the user; logged on their moderation history, no access change.
- **Suspend** — time-boxed loss of access (default 7 days, admin-adjustable); reversible.
- **Ban** — permanent loss of access; requires a reason code; not reversible from the standard UI.
- **Remove content** — deletes the specific reported photo/message/bio field without actioning the account (used for borderline content from otherwise-fine users).
- **Close report** — marks the report resolved with an outcome code (`no violation`, `warned`, `suspended`, `banned`, `content removed`).

**Standards**
- No account is banned by AI/automated action alone for non-zero-tolerance categories — a human reviews before ban.
- Every action against a user is logged with: admin id, action, reason, timestamp, linked report id (if any).
- Suspended/banned users cannot log in; their profile is immediately hidden from discovery, matches, and chat.
- Blocked-by-user relationships are enforced independently of admin action — blocking is a user-level control admins do not need to approve.

---

## 5. In-App Safety Reminders (placement)

| Location | Reminder |
|---|---|
| Onboarding (age step) | "You must be 18 or older to join. We verify age and may request ID if something looks off." *(ID check: placeholder)* |
| Discovery feed | Footer note: never share financial info before meeting; report anything that feels off. |
| New match / first chat message | "Never send money or personal info to someone you haven't met in person." |
| Report modal | Explicit list of what to never send (money, crypto, gift cards, passwords, private photos, ID). |
| Settings → Privacy & Safety | Blocked users list + link to Safety page and Community Guidelines. |
| Profile (location) | Only city + approximate distance shown, never exact location — no settings toggle exposes precise geo. |

---

## 6. Database Fields — Reports, Blocks, Bans, Moderation Status

```sql
-- Extends the core schema (profiles, photos, messages, matches, etc.)

-- ── Reports ─────────────────────────────────────────────
create table reports (
  id                uuid primary key default gen_random_uuid(),
  reporter_id       uuid not null references profiles(id),
  reported_user_id  uuid not null references profiles(id),
  reason_code       text not null check (reason_code in (
                      'inappropriate_photos','harassment','fake_profile_scam',
                      'money_request','underage','exploitation','stalking',
                      'spam','hate_speech','other'
                    )),
  free_text_detail  text,                         -- optional user-provided detail
  context_type      text check (context_type in ('profile','message','photo','match')),
  context_id        uuid,                          -- id of the reported message/photo/etc
  evidence_snapshot jsonb,                          -- preserved copy of reported content at report time
  status            text not null default 'pending'
                      check (status in ('pending','in_review','resolved')),
  outcome_code      text check (outcome_code in (
                      'no_violation','warned','suspended','banned','content_removed'
                    )),
  is_zero_tolerance boolean not null default false, -- auto-flagged, surfaces first in queue
  resolved_by       uuid references admin_users(id),
  resolved_at       timestamptz,
  created_at        timestamptz not null default now()
);
create index idx_reports_status on reports(status, is_zero_tolerance desc, created_at desc);
create index idx_reports_reported_user on reports(reported_user_id);

-- ── Blocks ──────────────────────────────────────────────
create table blocks (
  id            uuid primary key default gen_random_uuid(),
  blocker_id    uuid not null references profiles(id),
  blocked_id    uuid not null references profiles(id),
  created_at    timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);
create index idx_blocks_blocker on blocks(blocker_id);
create index idx_blocks_blocked on blocks(blocked_id);
-- Discovery/match/message queries must exclude any pair present in either direction.

-- ── Moderation actions (audit log) ─────────────────────
create table moderation_actions (
  id              uuid primary key default gen_random_uuid(),
  admin_id        uuid not null references admin_users(id),
  target_user_id  uuid not null references profiles(id),
  report_id       uuid references reports(id),
  action          text not null check (action in ('warn','suspend','ban','unban','remove_content')),
  reason_code     text,
  reason_detail   text,
  content_type    text,                     -- for remove_content: 'photo' | 'message' | 'bio'
  content_id      uuid,
  duration_days   int,                      -- for suspend, null = indefinite/until reviewed
  created_at      timestamptz not null default now()
);
create index idx_modactions_target on moderation_actions(target_user_id, created_at desc);

-- ── Moderation status on the user/profile record ───────
alter table profiles add column moderation_status text not null default 'active'
  check (moderation_status in ('active','warned','suspended','banned'));
alter table profiles add column suspended_until timestamptz;         -- null once expired/lifted
alter table profiles add column ban_reason_code text;
alter table profiles add column last_warned_at timestamptz;

-- ── Verification placeholders ──────────────────────────
alter table profiles add column photo_verified boolean not null default false;
alter table profiles add column photo_verification_status text default 'not_started'
  check (photo_verification_status in ('not_started','pending','approved','rejected'));
alter table profiles add column email_verified boolean not null default false;
alter table profiles add column phone_verified boolean not null default false;
alter table profiles add column device_fingerprint text;             -- for multi-account/ban-evasion detection
alter table profiles add column ai_moderation_flag_count int not null default 0; -- rolling count from automated scans

-- ── Law enforcement escalation (internal only, admin-restricted) ──
create table escalations (
  id            uuid primary key default gen_random_uuid(),
  report_id     uuid not null references reports(id),
  escalated_by  uuid not null references admin_users(id),
  category      text not null check (category in ('minor_safety','credible_threat','other_legal')),
  notes         text,
  created_at    timestamptz not null default now()
);
```

**RLS notes**
- `reports`: insertable by any authenticated user for `reporter_id = auth.uid()`; select restricted to the reporter (own reports) and admin role.
- `blocks`: insert/delete restricted to `blocker_id = auth.uid()`; readable by the blocker and by backend functions computing discovery/match/message eligibility.
- `moderation_actions`, `escalations`: admin-role only, no direct user access.
- All discovery, match-candidate, and message-send queries must join against `blocks` in both directions and exclude `moderation_status in ('suspended','banned')`.

**Geolocation constraint:** profiles store precise lat/long (PostGIS `geography(Point)`) for distance calculation server-side only; no API response ever includes raw coordinates — only a bucketed distance (e.g. "3 miles") and city name.
