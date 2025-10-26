#!/bin/sh
set -eu
# destroy-event-stack.sh — remove DDEV containers + project files

say(){ printf '%s\n' "[destroy] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)

say "Stopping and deleting Laravel + Moodle DDEV projects…"
for app in laravel moodle; do
  cd "$ROOT/apps/$app" 2>/dev/null || continue
  ddev stop || true
  ddev delete -Oy || true
done

say "Removing app folders…"
rm -rf "$ROOT/apps/laravel" "$ROOT/apps/moodle"

say "✅ Destroyed all local projects."