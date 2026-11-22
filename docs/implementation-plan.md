# Voice of Naney — Implementation Plan (MVP)

Builds on the agreed general plan. Every step lands on its own branch (`feat/`, `fix/` or `chore/`), is written test-first, and merges only when analyze, lint and tests are green.

## Decisions locked in
| Topic | Decision |
|---|---|
| Client | Flutter (web first; Android next; iOS later), `flutter_bloc`, `get_it` + `injectable`, `go_router` for deep links (`/r/<id>`) |
| Data + auth | Supabase (free tier): Postgres + PostGIS, RLS, invite-only auth with public sign-up disabled |
| Media + hosting | Cloudflare free tier: R2 bucket `naney-media`; one Worker serves the web build, `/api/*` and `/media/*` |
| Uploads | Presigned straight to R2. Single PUT for files ≤ 100 MB; multipart (resumable) above that. Max 50 MB audio, 500 MB video |
| Media delivery | `GET /media/<key>` through the Worker (R2 binding, HTTP Range support). No custom domain needed yet |
| Map | `flutter_map` + MapTiler tiles (labels in en or fa), clustered pins, shaded area outlines |
| Place search | Photon search + Nominatim boundary lookup, proxied and cached by the Worker so we stay within their usage policies |
| Moderation | None: uploads publish immediately. A `status` column (`published`/`hidden`) exists so admins can hide recordings |
| Revisions | `recording_media` table. Revision 0 is the original and is immutable. Admins add revisions 1, 2, … that sit alongside it; the newest plays by default and the original can still be selected |
| Curated lists | Start empty; admins fill them from the Streamlit panel |
| Admin panel | Local Streamlit app in `admin/` (`uv`), bound to `127.0.0.1`, never deployed |
| Secrets | `~/projects/naney-secrets/` (see below) |

## Secrets layout (outside the repo)
```
~/projects/naney-secrets/        (chmod 700)
  app.public.env       → compiled into the Flutter app: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, API_BASE_URL, MAPTILER_KEY
  server.secrets.env   → Worker + admin panel only: Supabase secret key / DB URL, Cloudflare account + API token, R2 S3 keys
```
- **Flutter:** `flutter run --dart-define-from-file=../../naney-secrets/app.public.env`.
- **Admin panel:** loads `../naney-secrets/server.secrets.env` by path.
- **Worker:** `scripts/push-worker-secrets.sh` sends only the keys the Worker needs to Cloudflare as encrypted Worker secrets. This is the **one** place a secret leaves this machine, and it is required for the Worker to run. For local `wrangler dev`, the same file is passed with `--env-file`.
- **CI (GitHub Actions)** never receives secrets: it only runs analyze, lint and tests against local, Docker-based Supabase. Deploys run from this machine.

---

## M0 — Scaffold (`chore/scaffold`)
The first commit on `main` is boilerplate only.
1. `git init`; add README, the existing CLAUDE.md and `.gitignore`.
2. `flutter create app --platforms=web,android,ios --org <reverse-domain>`.
   - Move `analysis_options.yaml` into `app/`.
   - Add the dependencies: `flutter_bloc`, `equatable`, `get_it`, `injectable`, `dio`, `supabase_flutter`, `go_router`, `flutter_localizations`/`intl`.
   - Add the dev dependencies: `bloc_test`, `mocktail`, `build_runner`, `injectable_generator`.
3. `app/lib/core/`:
   - DI bootstrap.
   - `AppConfig`, read from `--dart-define` values. The app fails fast if a value is missing.
   - Material 3 theme (light and dark), with the Vazirmatn font for Persian.
   - l10n skeleton (`app_en.arb`, `app_fa.arb`), router shell and locale switcher.
4. `worker/`:
   - Wrangler and TypeScript set up with `npm create cloudflare`, using an assets binding pointed at `../app/build/web` with SPA fallback.
   - Tests use `vitest` with `@cloudflare/vitest-pool-workers`; linting uses `eslint`.
   - `wrangler` is installed as a dev dependency (it isn't installed globally here).
5. `admin/`:
   - `uv init`, with `streamlit`, `supabase`, `boto3` and `python-dotenv`.
   - Dev tools: `pytest`, `ruff`, `mypy`.
6. `supabase init` (local stack runs in Docker through `supabase start`).
7. `.github/workflows/ci.yml` runs four jobs:
   - Flutter: analyze and test.
   - Worker: typecheck, lint and test.
   - Admin: ruff, mypy and pytest.
   - Database: `supabase start` followed by `supabase test db`.
8. Add the `scripts/` helpers: `dev.sh` and `push-worker-secrets.sh`.

## M1 — Database (`feat/db-schema`)
Migrations live in `supabase/migrations/` and the pgTAP tests in `supabase/tests/`.

**Tables**
- `profiles`
  - Columns: `id` (references `auth.users`), `role` (`admin` | `uploader`), `display_name`, `disabled`.
  - A trigger creates the profile automatically when a user is invited.
- `cultures`, `languages`: `name_en`, `name_fa`, `active`.
- `places`
  - Names and type: `name_en`, `name_fa`, `kind` (country, province, city, district, village or custom).
  - OpenStreetMap reference: `osm_type`, `osm_id` (unique when present).
  - Geometry: `area geography(MultiPolygon)`, simplified when inserted; `label_point geography(Point)`.
- `recordings`
  - Content: `title`, `description`, `kind` (lullaby, poem, wisdom, murmur or other), `tags text[]`, `transcript`, `photo_key`.
  - Performer: `performer_name` (nullable, so a performer can stay anonymous), `year_recorded`.
  - Origin: `language_id` or `language_other`, `place_id`, `origin_note`.
  - Consent: `consent_confirmed_at` (NOT NULL), `consent_by`.
  - `status`, `created_by` and timestamps.
- `recording_cultures`
  - Columns: `recording_id`, `position` (1–3), and either `culture_id` or `other_text` (a CHECK constraint requires exactly one).
  - A trigger enforces the maximum of 3.
- `recording_media`
  - Columns: `recording_id`, `revision_no`, `media_type`, `object_key`, `mime`, `size_bytes`, `duration_ms`, `note`, `created_by`.
  - `UNIQUE(recording_id, revision_no)`.
  - Revision 0 cannot be updated or deleted (enforced by a trigger).
- `uploads`
  - Records every presigned upload the Worker issues: `object_key`, owner, declared mime and size, `verified_at`.
  - Only the Worker writes this table, using the secret key.

**RPCs**
- `create_recording(payload)`
  - One transaction that inserts the recording, its cultures and media revision 0.
  - It requires every referenced object key to be a **verified** upload owned by the caller.
- `map_pins(bbox, filters)` returns one pin per place: label point, place name and recording count.
- `place_areas(bbox)` returns simplified outlines for zoomed-in views.
- `recording_detail(id)` returns the recording with its cultures, place and media revisions.

**RLS**
- Anonymous users can read published recordings and their child rows, plus `places`, `cultures` and `languages`.
- Uploaders can call `create_recording` and edit the metadata of their own recordings. They cannot change `status` and cannot touch revisions.
- Uploaders cannot delete anything (MVP).
- Admin actions go through the admin panel, which uses the secret key.

**Tests (pgTAP)**
- An anonymous user cannot see hidden recordings and cannot write anything.
- An uploader cannot edit another uploader's recording or change its `status`.
- `create_recording` rejects unverified or foreign uploads, zero cultures or more than 3, and a missing consent.
- Revision 0 cannot be changed.

## M2 — Public map + playback (`feat/public-map`, `feat/recording-page`, `feat/media-route`)
- **Worker `GET /media/:key`**
  - Streams the file from R2 and supports Range requests (`206`).
  - Sends caching headers; keys are random UUIDs.
  - Tests cover full and range requests, a 404, and path-traversal keys being rejected.
- **`features/map`**
  - `MapRepository`, backed by the RPCs.
  - `MapViewportCubit`: debounces viewport changes, then loads pins.
  - `MapFilterCubit`: culture, language, kind and tag filters.
  - Widgets: MapTiler tile layer (label language follows the app's locale), marker clusters, and a polygon layer for the selected place.
  - Tests: cubit tests for debounce, filtering and errors; widget tests that selecting a pin shows a preview sheet.
- **`features/recordings`**
  - `RecordingDetailCubit`.
  - Player abstraction: `just_audio` for audio, `video_player` for video.
  - Revision switcher (newest is the default, the original is selectable).
  - Shows the photo, transcript, cultures, origin note and an area mini-map.
  - Deep link: `/r/<id>`.
- Tests cover loading, error and hidden-or-not-found states, and revision selection.

## M3 — Auth + upload (`feat/auth`, `feat/upload-api`, `feat/geo-proxy`, `feat/upload-flow`)
- **Auth**
  - Invited users set a password through the invite link, then sign in with email and password.
  - `AuthBloc` handles session state; routes for uploaders and admins are guarded.
- **Worker `/api/uploads`**
  - Verifies the Supabase JWT against the project's JWKS (`jose`).
  - Loads the caller's profile and requires role `uploader` or `admin` and `disabled = false`.
  - Validates the declared mime type against the allow-list and the declared size against the per-type limit.
  - Inserts an `uploads` row and returns either one presigned PUT (`aws4fetch`, 15-minute expiry) or multipart part URLs.
  - Rate limit: at most N uploads per user per day.
- **Worker `/api/uploads/complete`**
  - Reads the object's metadata from R2 (`HEAD` via the binding).
  - Checks that the size and content type match the declaration, then sets `verified_at`.
  - On a mismatch it deletes the object and returns `422`.
  - Tests cover a missing or invalid JWT (401), the wrong role or a disabled user (403), a bad mime type or oversize file (400), a size mismatch (422), and the happy paths.
- **R2 CORS:** allow `PUT` from the app's origin(s) only.
- **Worker `/api/geo/search` and `/api/geo/boundary`**
  - Proxy Photon and Nominatim with an identifying User-Agent.
  - Cached at the edge and throttled to 1 request per second toward Nominatim.
  - Return GeoJSON.
- **`features/upload`**: `UploadBloc` drives a stepper with these steps:
  1. **Media**: pick a file (`file_picker`) or record in the browser (`record`: webm/opus on Chrome, mp4/aac on Safari); preview it.
  2. **Details**: title, kind, description, tags, performer (optional), year, language (from the list or "other"), transcript and photo.
  3. **Cultures**: 1–3 entries, each from the list or "other", plus an origin note.
  4. **Area**: search for a place, see its boundary on the map and confirm it; or draw a polygon and name it. Places that already exist are reused by `osm_id`.
  5. **Consent**: a required checkbox with clear text.
  6. **Submit**: uploads (with progress and multipart resume), then the complete call, then `create_recording`, then a jump to the new recording on the map.
- **Tests:**
  - Bloc tests for each step's validation, plus a submit test where the upload fails partway and is retried.
  - Widget tests: the submit button stays disabled until consent is given; a 4th culture cannot be added.

## M4 — Admin panel (`feat/admin-panel`)
`admin/` layout:
- `services/` holds plain Python logic that takes its clients as injected parameters.
- `pages/` holds the Streamlit UI.
- `config.py` loads `../naney-secrets/server.secrets.env` and fails fast if a value is missing.

Pages:
- **Cultures / Languages**: add, rename (en and fa), activate and deactivate. Nothing is ever hard-deleted, because recordings reference these rows.
- **Uploaders**: invite by email (Supabase admin `invite_user_by_email`), change role, disable or enable.
- **Recordings**: search and filter, view details and media, hide or unhide.
- **Revisions**: upload a new file for a recording to R2 via S3 (`boto3`). This inserts revision N+1 with a note; the original stays untouched.
- **Places**: rename (en and fa) and check outlines.

Run it with `uv run streamlit run app.py --server.address 127.0.0.1`.

Tests:
- `pytest` for the services, with mocked Supabase and S3 clients.
- `AppTest` smoke tests for each page.

## M5 — Ship web (`chore/deploy`)
1. Persian/RTL pass across all screens, plus widget tests that render in the `fa` locale.
2. Supabase production settings:
   - Disable sign-ups.
   - Set the site URL and redirect URLs to `https://naney.<account>.workers.dev`.
   - Push migrations with `supabase db push`.
3. R2: create the bucket and set CORS.
4. Push the Worker secrets, build with `flutter build web --release --dart-define-from-file=…`, then `wrangler deploy`.
5. Write `docs/security/mvp.md`, the security audit note covering auth, RLS, uploads, personal data and location privacy.
6. End-to-end check against the local stack (`supabase start` + `wrangler dev`): login → upload → pin on the map → playback.

## M6 — Post-MVP
- Android build and Play Store release (the `record` and `file_picker` packages already support it).
- iOS once there is an Apple developer account.
- Custom domain.
- Optional transcoding.

## Before M0 starts — what you need to do
1. Create the Supabase project (free) and the Cloudflare account (free). Enable R2 (it asks for a payment method even on the free tier) and create a MapTiler key.
2. Fill in `~/projects/naney-secrets/app.public.env` and `server.secrets.env`. The templates are already there; `API_BASE_URL` can stay empty until the first deploy.
3. Tell me the app's reverse-domain id for Android (e.g. `org.voiceofnaney.app`).
