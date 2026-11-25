# 0006 — The admin panel runs locally and is never deployed

**Status:** accepted

## Context
Admins manage culture and language lists, invite uploaders, reset passwords, hide recordings and
add revisions. These actions need the Supabase secret key and R2 write credentials.

## Options
- **Admin screens in the public app:** one codebase, but privileged code paths become reachable
  from the internet.
- **Local panel:** a Streamlit app bound to `127.0.0.1`, reading credentials from the local
  secrets folder.

## Decision
A local Streamlit panel. Business logic lives in typed, tested service modules (`mypy --strict`);
pages only render.

## Consequences
- No admin attack surface on the internet, and the secret key never reaches a browser.
- Only someone with the secrets folder can administer the archive.
