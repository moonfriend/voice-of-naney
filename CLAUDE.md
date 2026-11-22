# Voice of Naney — Project Guide

**Voice of Naney** is a tribute to El's grandmother: a crowdsourced archive of lullabies, poems,
words of wisdom, murmurings and other oral heritage. Every recording is tied to the culture(s)
and the geographic area it comes from.

## Product
- **Public visitors** (no login) browse a zoomable map, filter recordings, and listen or watch.
- **Uploaders** (trusted, invite-only) upload recordings with:
  - audio/video (from a file or recorded in the app), an optional photo and transcript;
  - tags, kind, language and 1–3 cultures/ethnicities, plus an optional origin note;
  - an origin **area**: an OpenStreetMap boundary or a polygon they draw;
  - a required consent confirmation.
- **Admins** use a **local Streamlit admin panel** (`admin/`, never deployed) to manage culture
  and language lists, invite uploaders, hide/unhide recordings and add **revisions** (a second
  file that sits alongside the original and never replaces it).
- No moderation for now: trusted uploads go live immediately.
- English and Persian, with full RTL support. Web first, then Android, then iOS, from one
  Flutter codebase.

## Architecture
- **App:** Flutter, feature-first Clean Architecture, `flutter_bloc`, `get_it` + `injectable`,
  `supabase_flutter` for data/auth, `dio` (auth-token interceptor) for the Worker API,
  `flutter_map` with clustering, `flutter gen-l10n` (en, fa).
- **Supabase:** Postgres + PostGIS, Auth, Row-Level Security.
- **Cloudflare:** R2 for media; one Worker serves the web build, the upload API, media (with
  HTTP range) and a geo proxy.
- **Uploads:** the Worker checks the Supabase token and role, issues presigned R2 URLs, and
  verifies the stored object before a recording can point to it. Media never goes through the
  Worker (100 MB request-body limit).
- **Maps:** tiles from a tile provider, never the public OSM tile servers. Place search and
  boundaries via Photon/Nominatim, within their usage policies, proxied by the Worker.
- **Revisions:** `recording_media` revision 0 is the uploader's original and is never deleted
  or overwritten; the public page plays the newest revision.
- **Portability:** only packages that support web, Android and iOS, or platform differences
  hidden behind an interface.

## Repo layout
- `app/` — Flutter app: `lib/features/<feature>/{data,domain,presentation}`.
- `supabase/` — migrations, seed data and pgTAP/RLS tests.
- `worker/` — Cloudflare Worker (TypeScript), vitest tests.
- `admin/` — local Streamlit admin panel (Python, `uv`); logic in service modules, pages only
  render.
- `docs/` — implementation plan, deploy guide, decision records, security notes.

## Project testing requirements
- RLS tests prove what anonymous users, uploaders and admins can and cannot access.
- Worker tests cover authentication, authorization and upload validation.
- Widget tests cover UI rules: consent checkbox, culture count limits, upload validation, RTL.
- An integration test covers the critical path: login → upload → recording on the public map →
  playback.
- This archive holds irreplaceable voices and family memories; a broken upload, a leaked hidden
  recording or a lost file may never be recoverable. Every change is tested.

## Secrets
- All credentials live **outside the repo**, in `../naney-secrets/`:
  - `app.public.env`: publishable values compiled into the app (`--dart-define-from-file`).
  - `server.secrets.env`: Worker secrets (pushed by script) and admin-panel credentials.
- Never copy, print, log, commit or send their contents. Never place a secrets file, `.env`,
  `.dev.vars` or key material in the repo.
- The Supabase secret key and the R2 S3 credentials never reach the Flutter app; only the Worker
  and the local admin panel use them.

## Security & privacy
- Origins are stored as areas (PostGIS multipolygon + label point), never a person's exact
  location.
- Culture/ethnicity, performer identity and voice recordings are sensitive personal data:
  collect the minimum and respect consent and the hidden status everywhere.
- Validate input in the app **and** on the server (RLS, constraints, Worker checks).

## Commits
Every commit message, merge commits included, ends with this trailer after a blank line:

```
AI-Generated: This code was written by an agentic coding assistant under human direction and review.
```
