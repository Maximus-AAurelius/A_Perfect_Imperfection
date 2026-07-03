# Perfect Imperfection

An authenticity-first dating and community platform.

**Core message:** Your imperfections are the point.

## Project Structure

```
Perfect Imperfection HQ/
├── 00_Master Plan/       # Project roadmap, milestones, decisions
├── 01_Brand/             # Brand guidelines, messaging, voice
├── 02_Product/           # Product specs, features, user flows
├── 03_Engineering/       # Tech documentation, architecture
├── 04_Safety/            # Safety policies, moderation rules
├── 05_Legal/             # ToS, Privacy Policy, legal documents
├── 06_Marketing/         # GTM strategy, campaigns, social content
├── 07_Prompts/           # Claude Code prompts, AI system instructions
├── 08_Research/          # Market research, competitor analysis
├── 09_Assets/            # Brand assets, mockups, images
├── 10_Archive/           # Deprecated content, old versions
│
├── app/                  # Next.js web application code
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── ...
│
├── CLAUDE.md             # AI assistant instructions for this project
├── README.md             # This file
└── .gitignore
```

## Quick Start

### Planning & Documentation

All planning, research, and strategy lives in Obsidian:
- Open the `.obsidian/` folder in Obsidian
- Start with `00_Master Plan/` for roadmap and current status
- Reference `CLAUDE.md` for how Claude Code should work on this project

### Web Application

The Next.js application is in the `/app` folder:

```bash
cd app
npm install
npm run dev
```

See `app/README.md` for development details.

## Systems

- **Obsidian** — Planning, notes, strategy (what to build)
- **GitHub** — Code, version control (how to build it)
- **Supabase** — Database, auth, storage (live app data)
- **Vercel** — Hosting and deployment (where it runs)

## Current Status

- ✓ Brand direction established
- ✓ MVP features defined
- ✓ Safety-first direction set
- ✓ Tech stack selected
- ✓ Obsidian vault organized
- ⏳ Next.js project to be initialized
- ⏳ Supabase setup pending
- ⏳ GitHub remote connection pending

## MVP Features

Core features for launch:
1. User signup/login
2. Profile creation & editing
3. Photo upload
4. Discovery cards
5. Like/pass system
6. Match system
7. Chat between matched users
8. Report/block user
9. Admin dashboard
10. Safety page & community guidelines

## How to Use This Repo

1. **Read CLAUDE.md** — Understand the project rules
2. **Check 00_Master Plan/** — See current priorities
3. **Open in Claude Code** — Get AI assistance
4. **Make changes** — Edit planning or code
5. **Commit to Git** — Save your work

## Important Links

- **CLAUDE.md** — Project instructions for Claude Code
- **00_Master Plan/** — Current roadmap and decisions
- **03_Engineering/** — Tech stack and setup docs
- **04_Safety/** — Safety policies and moderation rules

## Questions?

Refer to `CLAUDE.md` for how this project should be managed and developed.
