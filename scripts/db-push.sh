#!/usr/bin/env bash
# Applies supabase/migrations to the hosted project. Auth settings (sign-ups off,
# site URL, redirect URLs) are set in the dashboard — see docs/deploy.md.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

PROJECT_REF="$(read_secret "$SERVER_SECRETS_FILE" SUPABASE_PROJECT_REF)"
# The CLI reads the password from this variable, so it never appears in argv.
SUPABASE_DB_PASSWORD="$(read_secret "$SERVER_SECRETS_FILE" DB_PASSWORD)"
export SUPABASE_DB_PASSWORD

cd "$REPO_ROOT"
supabase link --project-ref "$PROJECT_REF"
supabase db push
