#!/usr/bin/env bash
# Applies supabase/migrations to the hosted project over a direct database connection
# (no Supabase CLI login needed). Pass --dry-run to only list pending migrations.
# Auth settings (sign-ups off, site/redirect URLs) are set in the dashboard — see docs/deploy.md.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

PROJECT_REF="$(read_secret "$SERVER_SECRETS_FILE" SUPABASE_PROJECT_REF)"
DB_URL="$(read_secret "$SERVER_SECRETS_FILE" DB_PASSWORD | python3 -c '
import sys, urllib.parse
password = urllib.parse.quote(sys.stdin.read(), safe="")
print(f"postgresql://postgres:{password}@db.{sys.argv[1]}.supabase.co:5432/postgres?sslmode=require")
' "$PROJECT_REF")"

cd "$REPO_ROOT"
supabase db push --db-url "$DB_URL" "$@"
