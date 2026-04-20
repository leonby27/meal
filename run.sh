#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/app"
if [ $# -eq 0 ]; then
  exec flutter run
fi
exec flutter "$@"
