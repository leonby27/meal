#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/app"

# Pull keys out of app/.env (gitignored) and turn each non-empty assignment
# into a --dart-define flag so Dart's `String.fromEnvironment(...)` can read
# them at compile-time. Lines starting with `#` or blank lines are skipped.
DART_DEFINES=()
if [[ -f .env ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    DART_DEFINES+=(--dart-define="$line")
  done < .env
fi

if [ $# -eq 0 ]; then
  exec flutter run "${DART_DEFINES[@]}"
fi
exec flutter "$@" "${DART_DEFINES[@]}"
