#!/usr/bin/env bash
# Shared helper: locate the secrets folder that lives OUTSIDE this repo.
# Values are read by path only and must never be echoed or logged.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${NANEY_SECRETS_DIR:-$(cd "$REPO_ROOT/.." && pwd)/naney-secrets}"
SERVER_SECRETS_FILE="$SECRETS_DIR/server.secrets.env"
APP_PUBLIC_FILE="$SECRETS_DIR/app.public.env"

# Prints the value of KEY from FILE (to stdout, for piping only).
read_secret() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || { echo "missing secrets file: $file" >&2; return 1; }
  local line
  line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
  local value="${line#*=}"
  [[ -n "$value" ]] || { echo "missing value for $key in $(basename "$file")" >&2; return 1; }
  printf '%s' "$value"
}
