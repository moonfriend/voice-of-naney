# Voice of Naney

A tribute to El's grandmother: a crowdsourced archive of lullabies, poems, words of wisdom
and murmurings, placed on a map by the culture and area they come from.

| Folder | What |
|---|---|
| `app/` | Flutter app (web first, Android/iOS later) |
| `worker/` | Cloudflare Worker: web hosting, upload API, media delivery |
| `supabase/` | Database migrations, seed and RLS tests |
| `admin/` | Local-only Streamlit admin panel |
| `docs/` | Plans and security notes |

Secrets live **outside** this repo in `../naney-secrets/` — see `CLAUDE.md`.

## Development

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

Deployment: see [docs/deploy.md](docs/deploy.md). Security notes: [docs/security/mvp.md](docs/security/mvp.md).
