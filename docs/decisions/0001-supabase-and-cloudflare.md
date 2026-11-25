# 0001 — Supabase for data and auth, Cloudflare for files and hosting

**Status:** accepted

## Context
The archive needs relational data with geography (areas, map queries), invite-only accounts with
roles, cheap storage for large audio and video, and hosting for a Flutter web build. Budget: free
tiers.

## Options
- **All-in-one (Supabase or Firebase only):** simplest, but storage egress is billed and video
  makes that the dominant cost.
- **Supabase + Cloudflare:** Postgres + PostGIS + Row-Level Security + Auth from Supabase; R2
  (no egress fees) and Workers (hosting + API) from Cloudflare.

## Decision
Supabase for the database and auth; Cloudflare R2 for media and one Worker for the web build, the
upload API, media delivery and a geo proxy.

## Consequences
- Two providers to operate, and the Worker must verify Supabase tokens itself (it calls Supabase
  Auth rather than trusting the signature alone, so revoked sessions fail immediately).
- Access rules live in one place (RLS) and are proven by pgTAP tests, which caught two real
  permission bugs before launch.
