#!/usr/bin/env bash
# Builds the web app with the public config and deploys it together with the Worker.
# Run tests first; this script refuses to deploy a dirty working tree.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

cd "$REPO_ROOT"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean; commit first." >&2
  exit 1
fi

for key in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY API_BASE_URL MAPTILER_KEY; do
  read_secret "$APP_PUBLIC_FILE" "$key" >/dev/null
done

(cd app && flutter build web --release --dart-define-from-file="$APP_PUBLIC_FILE")

CLOUDFLARE_API_TOKEN="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_API_TOKEN)"
CLOUDFLARE_ACCOUNT_ID="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_ACCOUNT_ID)"
export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID
(cd worker && npx wrangler deploy)
