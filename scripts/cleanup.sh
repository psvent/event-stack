#!/bin/sh
set -eu
# cleanup.sh — factory reset for event-stack (preserve repo + scripts/)
# Usage: ./scripts/cleanup.sh [--wipe-global]

ONLY_MOODLE=0
ONLY_LARAVEL=0
WIPE_GLOBAL=0

for arg in "$@"; do
  case "$arg" in
    --wipe-global) WIPE_GLOBAL=1 ;;
    --only-moodle) ONLY_MOODLE=1 ;;
    --only-laravel) ONLY_LARAVEL=1 ;;
  esac
done

say(){ printf '%s\n' "[cleanup] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# --------------------------------------------------------------------
# 1) Stop DDEV and delete known projects (by name)
# --------------------------------------------------------------------
say "Stopping DDEV router…"
ddev poweroff || true

if [ "$ONLY_MOODLE" -eq 1 ]; then
  say "Deleting Moodle projects only…"
  for n in "$(basename "$ROOT")-moodle" moodle; do
    ddev delete -Oy "$n" 2>/dev/null || true
  done
elif [ "$ONLY_LARAVEL" -eq 1 ]; then
  say "Deleting Laravel projects only…"
  for n in "$(basename "$ROOT")-laravel" laravel; do
    ddev delete -Oy "$n" 2>/dev/null || true
  done
else
  say "Deleting known DDEV projects (if present)…"
  for n in "$(basename "$ROOT")-laravel" "$(basename "$ROOT")-moodle" laravel moodle; do
    ddev delete -Oy "$n" 2>/dev/null || true
  done
fi

# --------------------------------------------------------------------
# 2) Docker prune (safe)
# --------------------------------------------------------------------
say "Pruning Docker artifacts…"
docker system prune -af 2>/dev/null || true
docker volume prune -f  2>/dev/null || true
docker network prune -f 2>/dev/null || true

# --------------------------------------------------------------------
# 3) Remove only generated workspace content
#    (preserve repo files and ALL scripts)
# --------------------------------------------------------------------
if [ "$ONLY_MOODLE" -eq 1 ]; then
  rm -rf "$ROOT/apps/moodle" "$ROOT/packages/moodle" "$ROOT/apps/moodle/.ddev" 2>/dev/null || true
elif [ "$ONLY_LARAVEL" -eq 1 ]; then
  rm -rf "$ROOT/apps/laravel" "$ROOT/packages/laravel" "$ROOT/apps/laravel/.ddev" 2>/dev/null || true
else
  rm -rf "$ROOT/apps" "$ROOT/packages" "$ROOT/.ddev" 2>/dev/null || true
fi

# Also remove any stray .ddev under the repo (belt-and-suspenders)
find "$ROOT" -type d -name ".ddev" -exec rm -rf {} + 2>/dev/null || true

# --------------------------------------------------------------------
# 4) Optional: wipe global DDEV config
# --------------------------------------------------------------------
if [ "$WIPE_GLOBAL" -eq 1 ]; then
  say "Removing global DDEV config at ~/.ddev …"
  rm -rf "$HOME/.ddev" 2>/dev/null || true
fi

# --------------------------------------------------------------------
# 5) Preserve everything in scripts/ and the Git repo
# --------------------------------------------------------------------
say "Preserving repository files and ALL scripts/ (no deletions here)."
# No action required — we intentionally do not touch scripts/ or Git.

# --------------------------------------------------------------------
# 6) Final status
# --------------------------------------------------------------------
say "✅ Cleanup complete."
say "Repo and scripts/ are intact. Rebuild with: ./scripts/setup.sh"