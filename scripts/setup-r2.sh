#!/usr/bin/env bash
# One-time: create the R2 bucket and allow browsers on our origins to PUT presigned uploads.
# ETag must be exposed so the app can complete multipart uploads.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

CLOUDFLARE_API_TOKEN="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_API_TOKEN)"
CLOUDFLARE_ACCOUNT_ID="$(read_secret "$SERVER_SECRETS_FILE" CLOUDFLARE_ACCOUNT_ID)"
export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID
BUCKET="$(read_secret "$SERVER_SECRETS_FILE" R2_BUCKET)"
APP_URL="$(read_secret "$SERVER_SECRETS_FILE" APP_PUBLIC_URL)"

CORS_FILE="$(mktemp)"
trap 'rm -f "$CORS_FILE"' EXIT
cat > "$CORS_FILE" <<JSON
{
  "rules": [
    {
      "allowed": {
        "origins": ["${APP_URL%/}", "http://localhost:8080", "http://127.0.0.1:8080"],
        "methods": ["PUT"],
        "headers": ["content-type"]
      },
      "exposeHeaders": ["ETag"],
      "maxAgeSeconds": 3600
    }
  ]
}
JSON

cd "$REPO_ROOT/worker"
npx wrangler r2 bucket create "$BUCKET" || echo "bucket $BUCKET may already exist"
npx wrangler r2 bucket cors set "$BUCKET" --file "$CORS_FILE" --force
echo "R2 bucket $BUCKET is ready."
