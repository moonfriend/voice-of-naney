# 0007 — Accept only formats browsers can play; no transcoding in the MVP

**Status:** accepted

## Context
Phones produce many formats: m4a (iPhone, Samsung, Google Recorder), mp4/mov (cameras), opus/ogg
(WhatsApp, Telegram voice notes), flac, and older amr/3gp, plus heic photos.

## Decision
Accept what browsers can play directly: mp3, m4a, aac, wav, ogg, opus, flac, webm, mp4, mov and
m4v. Defer amr, 3gp/3ga and heic until server-side conversion exists. The allow-list is enforced
identically in the app, the Worker and the admin panel, each with tests.

## Consequences
- No conversion infrastructure to run or pay for.
- Safari plays Ogg Opus unreliably, so some voice notes may not play on iPhones until conversion
  is added.
