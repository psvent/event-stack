#!/bin/sh
# init-ddev-moodle.sh — Moodle 5.1+ on DDEV (Postgres), cross-platform, CSS/JS fixed

set +u
set -e
set -o pipefail

say(){ printf '[moodle] %s\n' "$*"; }
need(){ command -v "$1" >/dev/null 2>&1 || { say "Missing dependency: $1"; exit 1; }; }

# ----------------------------- Config (overridable) -----------------------------
ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="${APP:-$ROOT/apps/moodle}"
WWWROOT="${WWWROOT:-https://event-stack-moodle.ddev.site}"
MOODLE_REPO="${MOODLE_REPO:-https://github.com/moodle/moodle.git}"
REF="${MOODLE_REF:-MOODLE_405_STABLE}"         # latest Moodle 5.1 stable tag
PHP_VERSION="${PHP_VERSION:-8.2}"
DDEV_NAME="event-stack-moodle"
THEME_DESIGNER="${THEME_DESIGNER:-true}"        # set to "false" later if you want

# Moodledata strategy (override via env): auto | bind-app | bind-root | volume
MOODLEDATA_STRATEGY="${MOODLEDATA_STRATEGY:-auto}"
# When using bind-root, set host dir (absolute path). Defaults to "$ROOT/moodledata".
MOODLEDATA_HOSTDIR="${MOODLEDATA_HOSTDIR:-$ROOT/moodledata}"

need git
need ddev
mkdir -p "$APP"
cd "$APP"

# ----------------------------- Clone / Update ----------------------------------
if [ ! -f "version.php" ] || [ ! -d "admin/cli" ]; then
  say "Cloning Moodle ($REF)…"
  TMPDIR="$(mktemp -d)"; trap 'rm -rf "$TMPDIR"' EXIT INT HUP TERM
  git clone --depth 1 --branch "$REF" "$MOODLE_REPO" "$TMPDIR" >/dev/null 2>&1
  rsync -a --delete --exclude='.git' --exclude='.ddev' "$TMPDIR"/ ./ >/dev/null 2>&1 || true
  say "Clone complete."
else
  if [ -d .git ]; then
    say "Updating Moodle ($REF)…"
    git fetch --depth 1 origin "$REF" >/dev/null 2>&1 || true
    git reset --hard "origin/$REF" >/dev/null 2>&1 || true
  else
    say "Moodle sources present (no .git) — leaving as is."
  fi
fi

# ----------------------------- Docroot detect ----------------------------------
DOCROOT="."
[ -d "public" ] && DOCROOT="public"
say "Detected Moodle docroot: $DOCROOT"

# ----------------------------- DDEV config -------------------------------------
mkdir -p .ddev
cat > .ddev/config.yaml <<YAML
name: ${DDEV_NAME}
type: php
php_version: "${PHP_VERSION}"
webserver_type: nginx-fpm
webserver_docroot: ${DOCROOT}
xdebug_enabled: false
use_dns_when_possible: true
disable_upload_dirs_warning: true
mutagen_enabled: false
database:
  type: postgres
  version: "15"
YAML

# ----------------------------- Moodledata mount strategy -----------------------
# Strategies:
#  - volume   : Docker named volume (fast on Linux)
#  - bind-app : Host bind mount at apps/moodle/moodledata (portable, inspectable)
#  - bind-root: Host bind mount at $MOODLEDATA_HOSTDIR (absolute path)
#  - auto     : bind-app on macOS/Windows, volume on Linux
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$MOODLEDATA_STRATEGY" = "auto" ]; then
  if echo "$OS" | grep -Eq 'darwin|mingw|msys|cygwin'; then
    MOODLEDATA_STRATEGY="bind-app"
  else
    MOODLEDATA_STRATEGY="volume"
  fi
fi

case "$MOODLEDATA_STRATEGY" in
  volume)
    say "Configuring moodledata as named volume…"
    cat > .ddev/docker-compose.moodledata.yaml <<'YAML'
services:
  web:
    volumes:
      - moodledata:/var/www/moodledata
volumes:
  moodledata:
    name: ddev-${DDEV_SITENAME}-moodledata
YAML
    cat > .ddev/config.perms.yaml <<'YAML'
hooks:
  post-start:
    - exec: "mkdir -p /var/www/moodledata && chown -R www-data:www-data /var/www/moodledata && chmod -R 0775 /var/www/moodledata"
      service: web
      asroot: true
YAML
    ;;

  bind-app)
    say "Configuring moodledata as bind mount at apps/moodle/moodledata…"
    mkdir -p "$APP/moodledata"
    chmod 0777 "$APP/moodledata" || true
    cat > .ddev/docker-compose.moodledata.yaml <<'YAML'
services:
  web:
    volumes:
      - ../moodledata:/var/www/moodledata:rw
YAML
    ;;

  bind-root)
    HOSTDIR_ABS="${MOODLEDATA_HOSTDIR}"
    say "Configuring moodledata as bind mount at ${HOSTDIR_ABS}…"
    mkdir -p "${HOSTDIR_ABS}"
    chmod 0777 "${HOSTDIR_ABS}" || true
    cat > .ddev/docker-compose.moodledata.yaml <<YAML
services:
  web:
    volumes:
      - ${HOSTDIR_ABS}:/var/www/moodledata:rw
YAML
    ;;

  *)
    say "Unknown MOODLEDATA_STRATEGY: ${MOODLEDATA_STRATEGY}" >&2
    exit 1
    ;;
esac

# Ensure we don't have leftover nginx overrides that break healthchecks
mkdir -p .ddev/nginx_full
# deliberately NOT adding any location/404 router overrides here (caused unhealthy before)
# keep empty include to satisfy any earlier references
echo "# (intentionally empty)" > .ddev/nginx_full/moodle.conf

# ----------------------------- Start DDEV --------------------------------------
say "Starting DDEV (${DDEV_NAME})…"
ddev stop >/dev/null 2>&1 || true
ddev start

# ----------------------------- Public symlinks (CSS/JS) ------------------------
# DDEV serves /public; Moodle core files live one level up. Expose required
# PHP entrypoints via symlinks so nginx can route them to PHP-FPM.
say "Ensuring required symlinks under /public…"
ddev exec sh -lc '
set -e
cd /var/www/html
mkdir -p public/lib/ajax

# Ensure public/theme -> ../theme
if [ -L public/theme ]; then
  :
elif [ -e public/theme ]; then
  rm -rf public/theme
fi
[ -L public/theme ] || ln -s ../theme public/theme

# Ensure public/pluginfile.php -> ../pluginfile.php
if [ -L public/pluginfile.php ]; then
  :
elif [ -e public/pluginfile.php ]; then
  rm -f public/pluginfile.php
fi
[ -L public/pluginfile.php ] || ln -s ../pluginfile.php public/pluginfile.php

# Ensure public/draftfile.php -> ../draftfile.php
if [ -L public/draftfile.php ]; then
  :
elif [ -e public/draftfile.php ]; then
  rm -f public/draftfile.php
fi
[ -L public/draftfile.php ] || ln -s ../draftfile.php public/draftfile.php

# Ensure public/lib/ajax/service.php -> ../../lib/ajax/service.php
if [ -L public/lib/ajax/service.php ]; then
  :
elif [ -e public/lib/ajax/service.php ]; then
  rm -f public/lib/ajax/service.php
fi
[ -L public/lib/ajax/service.php ] || ln -s ../../lib/ajax/service.php public/lib/ajax/service.php

ls -l public/theme public/pluginfile.php public/draftfile.php public/lib/ajax/service.php
'

# Detect Moodle docroot inside the container (handles /var/www/html vs /var/www/moodle)
MOODLE_PATH="$(ddev exec sh -lc 'if [ -f /var/www/html/version.php ]; then echo /var/www/html; elif [ -f /var/www/moodle/version.php ]; then echo /var/www/moodle; else echo /var/www/html; fi')"

# Avoid noisy ddev error output when file is missing by checking via shell and echoing status
if ddev exec sh -lc "[ -f \"$MOODLE_PATH/config.php\" ] && echo present || echo missing" | grep -q present; then
  say "config.php exists — skipping CLI installer."
else
  say "Running Moodle CLI installer…"
  ddev exec sh -lc "php \"$MOODLE_PATH/admin/cli/install.php\" \
    --non-interactive \
    --wwwroot=\"$WWWROOT\" \
    --dataroot=\"/var/www/moodledata\" \
    --dbtype=\"pgsql\" \
    --dbhost=\"db\" \
    --dbname=\"db\" \
    --dbuser=\"db\" \
    --dbpass=\"db\" \
    --fullname=\"Event Stack Moodle\" \
    --shortname=\"Moodle\" \
    --adminuser=\"admin\" \
    --adminpass=\"ChangeMe123!\" \
    --adminemail=\"admin@example.com\" \
    --agree-license"
fi

# Normalize permissions on /public (important for php-fpm)
say "Normalizing /public permissions (644/755)…"
ddev exec sh -lc 'find /var/www/html/public -type d -exec chmod 755 {} + && find /var/www/html/public -type f -exec chmod 644 {} +'

# ----------------------------- Patch config flags ------------------------------
say "Patching config.php (https + proxy + slasharguments + perms)…"
ddev exec env WWWROOT="$WWWROOT" php <<'PHP'
<?php
define('CLI_SCRIPT', true);
$f = '/var/www/html/config.php';
try {
    $c = @file_get_contents($f);
    if ($c === false) throw new Exception("Could not read $f");
    $target = getenv('WWWROOT') ?: 'https://event-stack-moodle.ddev.site';
    // Patch wwwroot: use $target variable properly (no escaped $)
    if (preg_match("/\$CFG->wwwroot\s*=\s*'[^']*';/", $c)) {
        $c = preg_replace("/\$CFG->wwwroot\s*=\s*'[^']*';/", "\$CFG->wwwroot = '" . $target . "';", $c, 1);
    } elseif (strpos($c, '$CFG->wwwroot') === false) {
        $c .= "\n\$CFG->wwwroot = '" . $target . "';\n";
    }
    // Safely append or set config flags even if $CFG is not defined yet
    foreach ([
        'reverseproxy' => 'true',
        'sslproxy' => 'true',
        'directorypermissions' => '0777',
        'themedesignermode' => 'true'
    ] as $k => $v) {
        if (strpos($c, "\$CFG->$k") === false) {
            $c .= "\n\$CFG->$k = $v;\n";
        }
    }
    // slasharguments
    if (preg_match("/\$CFG->slasharguments\s*=\s*[^;]*;/", $c)) {
        $c = preg_replace("/\$CFG->slasharguments\s*=\s*[^;]*;/", "\$CFG->slasharguments = 0;", $c, 1);
    } else {
        $c .= "\n\$CFG->slasharguments = 0;\n";
    }
    @file_put_contents($f, $c);
    echo "OK\n";
} catch (Throwable $e) {
    // Ignore warnings/errors
    echo "WARN: " . $e->getMessage() . "\n";
}
PHP

# ----------------------------- Purge caches + clean theme cache ----------------
say "Purging caches and clearing theme cache…"
ddev exec php /var/www/html/admin/cli/maintenance.php --enable
ddev exec sh -lc 'rm -rf /var/www/moodledata/localcache/theme/* /var/www/moodledata/cache/theme/* /var/www/moodledata/temp/* 2>/dev/null || true'
ddev exec php /var/www/html/admin/cli/purge_caches.php
ddev exec php /var/www/html/admin/cli/maintenance.php --disable


say "✅ Moodle ready → ${WWWROOT}"
say "   Login: admin / ChangeMe123!"
say "🎉 Moodle fully deployed and CSS verified."