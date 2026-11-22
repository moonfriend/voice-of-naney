# Setting up and deploying Voice of Naney

All credentials live in `~/projects/naney-secrets/` (outside this repo). Run
`./scripts/check-secrets.sh` at any time: it shows which keys are filled, never their values.

## 1. Accounts and keys (one time)

**Supabase** (free plan) → new project, then:
- `server.secrets.env`:
  - `SUPABASE_URL`: Project Settings → API (`https://<ref>.supabase.co`).
  - `SUPABASE_SECRET_KEY`: the **secret** key (`sb_secret_…`). Server-only.
  - `SUPABASE_PROJECT_REF`: the `<ref>` part of the URL.
  - `DB_PASSWORD`: the database password chosen when creating the project.
- `app.public.env`:
  - `SUPABASE_URL`: same as above.
  - `SUPABASE_PUBLISHABLE_KEY`: the **publishable** key (`sb_publishable_…`). Safe in the app.
- Authentication → Sign In / Providers:
  - Turn **off** "Allow new users to sign up".
  - Email provider on.
- Authentication → URL Configuration:
  - Site URL = `APP_PUBLIC_URL`.
  - Add `APP_PUBLIC_URL/set-password` to the redirect URLs.

**Cloudflare** (free plan):
- `CLOUDFLARE_ACCOUNT_ID`: Dashboard sidebar → Account ID.
- `CLOUDFLARE_API_TOKEN`: My Profile → API Tokens → create a token with
  *Workers Scripts: Edit* and *Workers R2 Storage: Edit* for your account.
- Enable R2. It asks for a payment method even on the free tier.
- R2 → Manage API tokens → create an **Object Read & Write** token for the `naney-media` bucket:
  - `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`: the S3 credentials of that token.
- `APP_PUBLIC_URL` (server) and `API_BASE_URL` (app): `https://naney.<your-subdomain>.workers.dev`.
  The subdomain is shown after the first deploy (Workers → Overview).

**MapTiler** (free plan) → Account → API keys → `MAPTILER_KEY` in `app.public.env`.
Restrict the key to your domain in MapTiler's settings, because it is visible in the app.

## 2. First deployment

```bash
./scripts/check-secrets.sh          # everything should say "ok"
./scripts/db-push.sh                # creates tables, policies and functions
./scripts/setup-r2.sh               # bucket + CORS for direct uploads
./scripts/push-worker-secrets.sh    # the only step that sends secrets anywhere (to Cloudflare)
./scripts/deploy.sh                 # builds the web app and deploys the Worker
```

Then invite yourself from the admin panel (`cd admin && uv run streamlit run app.py`) and make
yourself an admin there. Add the first cultures and languages in the panel as well.

## 3. Later deployments

```bash
./scripts/db-push.sh   # only when supabase/migrations changed
./scripts/deploy.sh
```
