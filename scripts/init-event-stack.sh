#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
chmod +x "$ROOT/scripts/init-ddev-laravel.sh" "$ROOT/scripts/init-ddev-moodle.sh"
"$ROOT/scripts/init-ddev-laravel.sh"
"$ROOT/scripts/init-ddev-moodle.sh"
echo "[stack] ✅ Laravel + Moodle initialized."