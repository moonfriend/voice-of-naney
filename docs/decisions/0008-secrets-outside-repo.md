# 0008 — Secrets live outside the repository

**Status:** accepted

## Decision
All credentials live in a sibling folder (`../naney-secrets/`, `chmod 700`), split into
publishable values compiled into the app and server-only secrets. Scripts read them by path and
pass them via stdin or environment, never command-line arguments; error messages name missing
keys, never values. `.gitignore` blocks env and key files as a second line of defence, and CI
needs no secrets.

## Consequences
- The repository can be public without leaking anything.
- A new machine needs the secrets folder copied over by hand.
