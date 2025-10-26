#!/bin/sh
set -eu
# gen-moodle-plugin-mounts.sh — regenerate Moodle plugin mounts for DDEV
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGINS="$ROOT/packages/moodle-plugins"
APP="$ROOT/apps/moodle"
CONF="$APP/.ddev/mounts.yaml"

echo "[moodle] Generating DDEV mounts.yaml…"
mkdir -p "$APP/.ddev"

cat > "$CONF" <<EOF
# Auto-generated Moodle plugin mounts
version: v1
web_extra_service_mounts:
EOF

for plugin in "$PLUGINS"/*; do
  [ -d "$plugin" ] || continue
  name=$(basename "$plugin")
  echo "  - source: ../../packages/moodle-plugins/$name" >> "$CONF"
  echo "    destination: /var/www/html/local/$name" >> "$CONF"
done

echo "[moodle] mounts.yaml written → $CONF"