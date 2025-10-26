#!/bin/sh
set -e
# setup.sh — one-shot installer for event-stack (Laravel + Moodle)
# runs bootstrap if needed, installs both, and starts everything.

say(){ printf '%s\n' "[setup] $*"; }
die(){ printf '%s\n' "[setup] ERROR: $*" >&2; exit 1; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ -d "$ROOT/scripts" ] || die "scripts directory missing"

chmod +x "$ROOT"/scripts/*.sh 2>/dev/null || true


say "→ Initializing Laravel…"
"$ROOT/scripts/init-ddev-laravel.sh"
say "→ Initializing Moodle…"
"$ROOT/scripts/init-ddev-moodle.sh"

say "✅ Setup complete."
say "Laravel → https://event-stack-laravel.ddev.site"
say "Moodle  → https://event-stack-moodle.ddev.site"
say "Mailpit → run './scripts/dev.sh mail'"