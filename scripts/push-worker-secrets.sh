#!/usr/bin/env bash
# Pushes ONLY the secrets the Worker needs to Cloudflare's encrypted secret store.
# Values are piped via stdin so they never appear in argv, shell history or logs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

WORKER_KEYS=(SUPABASE_URL SUPABASE_SECRET_KEY CLOUDFLARE_ACCOUNT_ID R2_BUCKET R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY)

CLOUDFLARE_API_TOKEN="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_API_TOKEN)"
CLOUDFLARE_ACCOUNT_ID="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_ACCOUNT_ID)"
export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID

cd "$REPO_ROOT/worker"
for key in "${WORKER_KEYS[@]}"; do
  read_secret "$SERVER_SECRETS_FILE" "$key" | npx wrangler secret put "$key" >/dev/null
  echo "pushed $key"
done
