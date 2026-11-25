# 0005 — Revisions sit alongside the original, never replace it

**Status:** accepted

## Context
There is no moderation in the MVP, but admins may need to improve a file (a cleaner cut, better
audio) without losing what the family originally shared.

## Decision
A recording has one or more media files. Revision 0 is the uploader's original: a database
trigger refuses to update or delete it, even with the secret key. Admins add later revisions; the
public page plays the newest one and the original stays available.

## Consequences
- An irreplaceable recording cannot be lost by an edit.
- Storage grows with each revision; acceptable at archive scale.
