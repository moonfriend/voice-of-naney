# Architecture decision records

Short records of the decisions that shaped Voice of Naney: the problem, the options weighed,
the choice, and its consequences.

| # | Decision |
|---|---|
| [0001](0001-supabase-and-cloudflare.md) | Supabase for data and auth, Cloudflare for files and hosting |
| [0002](0002-direct-to-r2-uploads.md) | Uploads go straight to R2 with presigned URLs |
| [0003](0003-origins-are-areas.md) | A recording's origin is an area, not a point |
| [0004](0004-multiple-cultures.md) | One to three cultures per recording, plus an origin note |
| [0005](0005-revisions-never-replace.md) | Revisions sit alongside the original, never replace it |
| [0006](0006-local-admin-panel.md) | The admin panel runs locally and is never deployed |
| [0007](0007-no-transcoding-in-mvp.md) | Accept only formats browsers can play; no transcoding in the MVP |
| [0008](0008-secrets-outside-repo.md) | Secrets live outside the repository |
