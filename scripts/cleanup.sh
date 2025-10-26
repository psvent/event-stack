#!/bin/sh
set -eu
# cleanup.sh — factory reset for event-stack
# Usage: ./scripts/cleanup.sh [--wipe-global]

WIPE_GLOBAL=0
[ "${1-}" = "--wipe-global" ] && WIPE_GLOBAL=1

say(){ printf '%s\n' "[cleanup] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)

say "Stopping DDEV…"
ddev poweroff || true

say "Deleting known projects…"
for n in "$(basename "$ROOT")-laravel" "$(basename "$ROOT")-moodle" laravel moodle; do
  ddev delete -Oy "$n" 2>/dev/null || true
done

say "Pruning Docker artifacts…"
docker system prune -af 2>/dev/null || true
docker volume prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true

say "Removing local folders…"
rm -rf "$ROOT/apps" "$ROOT/packages" "$ROOT/docs" "$ROOT/.git" "$ROOT/.gitignore" "$ROOT/README.md" 2>/dev/null || true
find "$ROOT" -maxdepth 5 -type d -name ".ddev" -exec rm -rf {} + 2>/dev/null || true

if [ "$WIPE_GLOBAL" -eq 1 ]; then
  say "Removing global ~/.ddev …"
  rm -rf "$HOME/.ddev" || true
fi

say "Preserving only scripts/"
find "$ROOT/scripts" -type f ! -name "cleanup.sh" -delete 2>/dev/null || true
say "✅ Cleanup complete. Run ./scripts/setup.sh to rebuild."