# 0004 — One to three cultures per recording, plus an origin note

**Status:** accepted

## Context
Families move and mix. A lullaby may be Azeri sung by a Kurdish-Azeri family that moved from Urmia
to Tabriz. A single "ethnicity" field would force a false choice.

## Decision
Each recording has one to three ordered culture entries (primary first). Each is either from the
curated list or "other" with free text. A free-text origin note explains anything further.

## Consequences
- The curated list stays clean while still accepting what is missing from it.
- Culture is sensitive personal data: it is required only as far as the archive needs it, and the
  limit (1–3, no duplicates) is enforced in the app, the database function and its tests.
