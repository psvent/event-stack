#!/bin/sh
set -eu
say(){ printf '%s\n' "[moodle] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="$ROOT/apps/moodle"
PN="$(basename "$ROOT")-moodle"

mkdir -p "$APP"
cd "$APP"

[ -f .ddev/config.yaml ] && { ddev stop || true; ddev delete -Oy || true; rm -rf .ddev; }
ddev delete -Oy "$PN" || true

say "Configuring Moodle (Postgres 15)…"
ddev config --project-type=php --docroot=. --php-version=8.3 --database=postgres:15 --project-name="$PN"
ddev start

find . -mindepth 1 -maxdepth 1 ! -name '.ddev' -exec rm -rf {} +
git clone --depth=1 --branch MOODLE_501_STABLE https://github.com/moodle/moodle .

ddev exec mkdir -p /var/www/html/moodledata
ddev exec chown -R www-data:www-data /var/www/html/moodledata

say "Installing Moodle via CLI…"
ddev exec php admin/cli/install.php \
  --non-interactive \
  --lang=en \
  --wwwroot=https://moodle.ddev.site \
  --dataroot=/var/www/html/moodledata \
  --dbtype=pgsql \
  --dbhost=db \
  --dbname=db \
  --dbuser=db \
  --dbpass=db \
  --fullname='Event Stack Moodle' \
  --shortname='Moodle' \
  --adminuser=admin \
  --adminpass='ChangeMe123!' \
  --adminemail='admin@example.com' \
  --agree-license

say "Moodle ready → https://moodle.ddev.site"