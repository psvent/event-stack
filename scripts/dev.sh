#!/bin/sh
set -eu
# dev.sh — control both DDEV apps from repo root
CMD="${1-}"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
L="$ROOT/apps/laravel"
M="$ROOT/apps/moodle"

usage() {
  cat <<EOF
Usage: ./scripts/dev.sh <command>

Commands:
  start        Start both DDEV projects
  stop         Stop both
  restart      Restart both
  status       Show DDEV status
  launch       Open both sites
  mail         Open both Mailpit UIs
  poweroff     Power off all DDEV containers
EOF
}

[ -n "$CMD" ] || { usage; exit 2; }

case "$CMD" in
  start)    (cd "$L" && ddev start); (cd "$M" && ddev start) ;;
  stop)     (cd "$L" && ddev stop || true); (cd "$M" && ddev stop || true) ;;
  restart)  (cd "$L" && ddev restart); (cd "$M" && ddev restart) ;;
  status)   ddev list ;;
  launch)   (cd "$L" && ddev launch || true); (cd "$M" && ddev launch || true) ;;
  mail)     (cd "$L" && ddev launch -m || true); (cd "$M" && ddev launch -m || true) ;;
  poweroff) ddev poweroff ;;
  *) usage; exit 2 ;;
esac