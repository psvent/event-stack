mkdir -p scripts
cat > scripts/custom-ddev-commands <<'BASH'
#!/usr/bin/env bash
# Install/update custom DDEV commands into app .ddev folders (Moodle/Laravel).
# For now we add only: install-moodle-plugin (host command under apps/moodle)

set -euo pipefail
IFS=$'\n\t'

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MOODLE_APP="${MOODLE_APP:-$ROOT/apps/moodle}"
LARAVEL_APP="${LARAVEL_APP:-$ROOT/apps/laravel}"

say(){ printf '[custom-ddev-commands] %s\n' "$*"; }

install_cmd_install_moodle_plugin() {
  local cmd_dir="$MOODLE_APP/.ddev/commands/host"
  local cmd_path="$cmd_dir/install-moodle-plugin"
  mkdir -p "$cmd_dir"
  cat >"$cmd_path" <<'CMD'
#!/usr/bin/env bash
# ddev install-moodle-plugin <plugin_path>
# Example: ddev install-moodle-plugin ../packages/moodle-plugins/myplugin
set -euo pipefail
IFS=$'\n\t'

PLUGIN_SRC="${1:-}"
if [ -z "$PLUGIN_SRC" ]; then
  echo "Usage: ddev install-moodle-plugin <path-to-plugin>" >&2
  exit 1
fi
if [ ! -d "$PLUGIN_SRC" ]; then
  echo "❌ Plugin path not found: $PLUGIN_SRC" >&2
  exit 1
fi

# Normalize path and derive plugin name
PLUGIN_SRC_ABS="$(cd "$PLUGIN_SRC" && pwd)"
PLUGIN_NAME="$(basename "$PLUGIN_SRC_ABS")"

# Compute path relative to apps/moodle (for mounts.yaml)
ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"  # .../apps/moodle
REL_FROM_MOODLE="$(python3 - <<PY
import os,sys
moodle=os.path.abspath(sys.argv[1])
src=os.path.abspath(sys.argv[2])
print(os.path.relpath(src, moodle))
PY
"$ROOT_DIR" "$PLUGIN_SRC_ABS")"

MOUNT_YAML="$ROOT_DIR/.ddev/mounts.yaml"
mkdir -p "$(dirname "$MOUNT_YAML")"
if ! grep -q '^web_extra_service_mounts:' "$MOUNT_YAML" 2>/dev/null; then
  cat >"$MOUNT_YAML" <<YAML
# Auto-generated Moodle plugin mounts
version: v1
web_extra_service_mounts:
YAML
fi

# Append mapping if not present yet
if ! grep -q "/local/$PLUGIN_NAME" "$MOUNT_YAML"; then
  { echo "  - source: ../../$REL_FROM_MOODLE"; echo "    destination: /var/www/html/local/$PLUGIN_NAME"; } >>"$MOUNT_YAML"
  echo "[moodle] Mount added for plugin '$PLUGIN_NAME'"
else
  echo "[moodle] Mount already exists for plugin '$PLUGIN_NAME'"
fi

echo "[moodle] Restarting DDEV to apply mount…"
ddev restart >/dev/null

echo "[moodle] ✅ Plugin '$PLUGIN_NAME' mounted at /local/$PLUGIN_NAME"
CMD
  chmod +x "$cmd_path" || true
  say "Installed ddev command: apps/moodle/.ddev/commands/host/install-moodle-plugin"
}

main() {
  install_cmd_install_moodle_plugin
  # Prepare Laravel commands folder for future commands (placeholder)
  mkdir -p "$LARAVEL_APP/.ddev/commands/host"
  : > "$LARAVEL_APP/.ddev/commands/host/.keep"
  say "Laravel commands folder prepared (placeholder)."
  say "Done. You can now run: ddev install-moodle-plugin ../packages/moodle-plugins/yourplugin"
}
main "$@"
BASH
chmod +x scripts/custom-ddev-commands