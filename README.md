# Voice of Naney

[![CI](https://github.com/moonfriend/voice-of-naney/actions/workflows/ci.yml/badge.svg)](https://github.com/moonfriend/voice-of-naney/actions/workflows/ci.yml)

A tribute to El's grandmother: a crowdsourced archive of lullabies, poems, words of wisdom and
murmurings, placed on a map by the culture and area they come from.

**Live:** https://naney.hamyar-de.workers.dev

- Anyone can explore the map and listen or watch, without an account.
- Invited contributors upload audio or video (or record in the browser), describe it, choose 1–3
  cultures and mark the origin area — an OpenStreetMap boundary or a hand-drawn region.
- English and Persian, with full right-to-left layout.

## Architecture

```
                 Flutter app (web now · Android next · iOS later)
          ┌──────────────────┬─────────────────────────┬───────────────────┐
          ▼                  ▼                         ▼                   │
   Supabase Auth      Cloudflare Worker           Cloudflare R2           │
   Postgres+PostGIS   · serves the web build      · audio, video, photos  │
   Row-Level Security · upload API: checks token, ◄─ direct upload with ──┘
                        signs R2 URLs, verifies      presigned URLs
                        what arrived
                      · /media with byte ranges
                      · geo proxy (Photon/Nominatim, cached)

   Local only:  Streamlit admin panel ── secret key ──► Supabase, R2
```

| Folder | What | Stack |
|---|---|---|
| `app/` | Web/mobile app | Flutter, Clean Architecture, flutter_bloc, get_it/injectable, flutter_map |
| `worker/` | Hosting, upload API, media, geo proxy | TypeScript, Cloudflare Workers, aws4fetch |
| `supabase/` | Schema, access rules, database functions | Postgres, PostGIS, RLS, pgTAP |
| `admin/` | Local-only admin panel | Python, Streamlit, uv, mypy --strict |
| `docs/` | Plan, deploy guide, decisions, security notes | |

## Key decisions

Full records in [docs/decisions](docs/decisions/README.md).

- **Uploads skip the server.** Files go straight to storage with short-lived signed URLs, in
  retryable parts for large videos. The Worker only authorizes and then verifies what arrived. This
  makes 500 MB uploads possible on the free plan, where Workers cap request bodies at 100 MB.
- **Origins are areas, not points.** A recording belongs to "Tabriz" or "the villages around
  Maragheh", never to a GPS position, so privacy is built into the data model.
- **Mixed heritage is first-class.** One to three cultures per recording, plus a free-text note
  for families that moved or mixed.
- **Originals are immutable.** Admins can add improved revisions; a database trigger guarantees the
  family's original file is never altered or deleted.
- **No admin surface on the internet.** Privileged actions run from a local panel; the secret key
  never reaches a browser.

## Quality

Every feature is test-first, and CI runs all suites on each push.

| Suite | Tests | Covers |
|---|---|---|
| Flutter | 156 | cubits, repositories, widget rules (consent, culture limits, upload validation, RTL) |
| Worker | 116 | auth, roles, quotas, upload validation, signing, media ranges, geo proxy |
| Admin | 64 | services, validation, pages (Streamlit AppTest) |
| Database | pgTAP | what visitors, uploaders and admins can and cannot read or write |

The database access tests found two real permission bugs before launch. A live smoke test
(`scripts/smoke_upload.py`) exercises the deployed upload path end to end.

Security and privacy notes: [docs/security/mvp.md](docs/security/mvp.md).

## Development

Secrets live **outside** this repo in `../naney-secrets/` and are never committed.

```bash
# Flutter app
cd app && flutter test && flutter analyze
# Worker
cd worker && npm test && npm run typecheck && npm run lint
# Admin panel (local only)
cd admin && uv run pytest && uv run streamlit run app.py
# Database (Docker): local stack + pgTAP tests
supabase start && supabase test db
```

Deployment: [docs/deploy.md](docs/deploy.md).

## How this was built

The code was written by an agentic coding assistant under my direction and review: I set the
product, architecture, engineering standards and every key decision above. Each commit carries an
`AI-Generated` trailer saying so.
