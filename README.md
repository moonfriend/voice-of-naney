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
