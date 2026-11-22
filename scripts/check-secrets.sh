#!/usr/bin/env bash
# Lists which expected keys are filled in — names only, never values.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

check() {
  local file="$1"; shift
  echo "== $(basename "$file")"
  for key in "$@"; do
    if read_secret "$file" "$key" >/dev/null 2>&1; then echo "  ok      $key"; else echo "  MISSING $key"; fi
  done
}

check "$APP_PUBLIC_FILE" SUPABASE_URL SUPABASE_PUBLISHABLE_KEY API_BASE_URL MAPTILER_KEY
check "$SERVER_SECRETS_FILE" SUPABASE_URL SUPABASE_SECRET_KEY SUPABASE_PROJECT_REF DB_PASSWORD \
  CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_TOKEN R2_BUCKET R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY APP_PUBLIC_URL
