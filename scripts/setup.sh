#!/bin/sh
set -eu
# setup.sh — one-shot installer for event-stack (Laravel + Moodle)
# runs bootstrap if needed, installs both, and starts everything.

say(){ printf '%s\n' "[setup] $*"; }
die(){ printf '%s\n' "[setup] ERROR: $*" >&2; exit 1; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -d "$ROOT/scripts" ] || die "scripts directory missing"

# run bootstrap if apps/packages missing
if [ ! -d "$ROOT/apps" ] || [ ! -d "$ROOT/packages" ]; then
  if [ -x "$ROOT/scripts/bootstrap.sh" ]; then
    say "Scaffold missing → running bootstrap.sh…"
    "$ROOT/scripts/bootstrap.sh"
  fi
fi

chmod +x "$ROOT"/scripts/*.sh 2>/dev/null || true

if [ -x "$ROOT/scripts/init-all.sh" ]; then
  "$ROOT/scripts/init-all.sh"
else
  "$ROOT/scripts/init-ddev-laravel.sh"
  "$ROOT/scripts/init-ddev-moodle.sh"
fi

say "✅ Setup complete."
say "Laravel → https://laravel.ddev.site"
say "Moodle  → https://moodle.ddev.site"
say "Mailpit → run './scripts/dev.sh mail'"