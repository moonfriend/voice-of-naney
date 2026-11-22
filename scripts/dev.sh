#!/usr/bin/env bash
# Local development stack: Supabase (Docker) + Flutter web on :8080.
# The Worker runs separately: (cd worker && npm run dev).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-secrets.sh"

cd "$REPO_ROOT"
supabase start
cd app
flutter run -d web-server --web-port 8080 --dart-define-from-file="$APP_PUBLIC_FILE"
