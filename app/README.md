# Perfect Imperfection Web App

Next.js + Supabase + Tailwind CSS dating platform.

## Project Structure

```
app/
├── src/
│   ├── app/           # Next.js app directory
│   ├── components/    # Reusable React components
│   ├── lib/          # Utility functions
│   ├── styles/       # CSS files
│   └── utils/        # Helper functions
├── public/           # Static files
├── assets/           # Brand assets, images
├── screenshots/      # App screenshots, mockups
├── uploads/          # User uploads (local, for reference)
├── package.json
├── next.config.js
└── tailwind.config.js
```

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Supabase account and project
- Environment variables configured

### Installation

```bash
cd app
npm install
```

### Environment Variables

Create `.env.local` (do not commit):

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SITE_URL=http://localhost:3000
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
```

Copy from `.env.example` and fill in your values.

### Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build

```bash
npm run build
npm start
```

### Deployment

Deploy to Vercel with:

```bash
vercel deploy
```

## Tech Stack

- **Frontend:** Next.js, React, Tailwind CSS
- **Backend:** Supabase, PostgreSQL
- **Auth:** Supabase Auth
- **Storage:** Supabase Storage
- **Realtime:** Supabase Realtime
- **Hosting:** Vercel
- **Payments:** Stripe (future)

## MVP Features

- [x] Project setup (in progress)
- [ ] Landing page
- [ ] User signup/login
- [ ] Profile creation & editing
- [ ] Photo upload
- [ ] Discovery cards
- [ ] Like/pass system
- [ ] Matching algorithm
- [ ] Chat between matches
- [ ] Report/block user
- [ ] Admin dashboard
- [ ] Safety pages

## Testing Checklist

Before each deployment, test:
- [ ] Desktop layout
- [ ] Mobile layout
- [ ] Logged-out state
- [ ] Logged-in state
- [ ] Loading states
- [ ] Error states
- [ ] Permission restrictions
- [ ] Report/block functionality

## Security

- Use Supabase Row Level Security (RLS)
- Never expose service role keys in frontend
- Validate all inputs server-side
- Use environment variables for secrets
- Protect admin routes

See `/04_Safety` in project root for safety policies.

## Documentation

- `CLAUDE.md` (project root) — How Claude Code works on this project
- `/03_Engineering/` — Tech documentation
- `/04_Safety/` — Safety and moderation rules

## Support

Refer to the project root's `README.md` for overall project structure and guidelines.
