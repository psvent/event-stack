#!/bin/sh
set -eu
# cleanup.sh — factory reset for event-stack (preserve repo + scripts/)
# Usage: ./scripts/cleanup.sh [--wipe-global]

WIPE_GLOBAL=0
[ "${1-}" = "--wipe-global" ] && WIPE_GLOBAL=1

say(){ printf '%s\n' "[cleanup] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# --------------------------------------------------------------------
# 1) Stop DDEV and delete known projects (by name)
# --------------------------------------------------------------------
say "Stopping DDEV router…"
ddev poweroff || true

say "Deleting known DDEV projects (if present)…"
for n in "$(basename "$ROOT")-laravel" "$(basename "$ROOT")-moodle" laravel moodle; do
  ddev delete -Oy "$n" 2>/dev/null || true
done

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
say "Removing generated folders (apps/, packages/)…"
rm -rf "$ROOT/apps" "$ROOT/packages" 2>/dev/null || true

# Belt-and-suspenders: remove any nested .ddev under repo (but not at root)
find "$ROOT" -path "$ROOT/.ddev" -prune -o -type d -name ".ddev" -exec rm -rf {} + 2>/dev/null || true

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