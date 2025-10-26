#!/bin/sh
set -eu
# init-ddev-laravel.sh — Idempotent Laravel setup on DDEV (Postgres 15)

say() { printf '%s\n' "[laravel] $*"; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="$ROOT/apps/laravel"

# Stable project name and URL (no bashisms, set BEFORE use)
REPO_NAME=$(basename "$ROOT")
PN="${REPO_NAME}-laravel"               # e.g. event-stack-laravel
URL="https://${PN}.ddev.site"

# Ensure app folder exists
mkdir -p "$APP"
cd "$APP"

say "Cleaning Laravel folder (preserving .ddev if present)…"
# Remove everything except .ddev (bind-mount safe); ignore errors if empty
find . -mindepth 1 -maxdepth 1 ! -name '.ddev' -exec rm -rf {} + 2>/dev/null || true

# If a local project exists, reset it cleanly
if [ -f .ddev/config.yaml ]; then
  say "Removing existing local DDEV project…"
  ddev stop || true
  ddev delete -Oy || true
  rm -rf .ddev
fi

# Also remove any global project with same name
say "Ensuring no conflicting global project named ${PN}…"
ddev delete -Oy "$PN" || true

say "Configuring DDEV (Laravel + Postgres 15) as '${PN}'…"
ddev config --project-type=laravel --docroot=public \
  --php-version=8.3 --database=postgres:15 --nodejs-version=20 \
  --project-name="$PN"

ddev start

# Install Laravel only if composer.json is missing
if [ ! -f composer.json ]; then
  say "Installing Laravel via Composer (this can take a minute)…"
  ddev composer create-project --prefer-dist laravel/laravel .
fi

say "Generating APP_KEY…"
ddev artisan key:generate || true

# Patch .env for Postgres + Mailpit + correct APP_URL
if [ -f .env ]; then
  say "Patching .env for Postgres + Mailpit + URL…"
  # DB
  awk '
    BEGIN{FS=OFS="="}
    /^DB_CONNECTION=/{ $2="pgsql" }
    /^DB_HOST=/{ $2="db" }
    /^DB_PORT=/{ $2="5432" }
    /^DB_DATABASE=/{ $2="db" }
    /^DB_USERNAME=/{ $2="db" }
    /^DB_PASSWORD=/{ $2="db" }
    {print}
  ' .env > .env.tmp && mv .env.tmp .env

  # APP_URL and Mailpit
  # (Use sed with safe delimiter to inject URL)
  sed -i '' -e "s#^APP_URL=.*#APP_URL=${URL}#g" .env 2>/dev/null || \
  sed -i -e "s#^APP_URL=.*#APP_URL=${URL}#g" .env

  sed -i '' -e 's/^MAIL_MAILER=.*/MAIL_MAILER=smtp/g' .env 2>/dev/null || sed -i -e 's/^MAIL_MAILER=.*/MAIL_MAILER=smtp/g' .env
  sed -i '' -e 's/^MAIL_HOST=.*/MAIL_HOST=localhost/g' .env 2>/dev/null || sed -i -e 's/^MAIL_HOST=.*/MAIL_HOST=localhost/g' .env
  sed -i '' -e 's/^MAIL_PORT=.*/MAIL_PORT=1025/g' .env 2>/dev/null || sed -i -e 's/^MAIL_PORT=.*/MAIL_PORT=1025/g' .env
  sed -i '' -e 's/^MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=null/g' .env 2>/dev/null || sed -i -e 's/^MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=null/g' .env
  sed -i '' -e 's/^MAIL_USERNAME=.*/MAIL_USERNAME=null/g' .env 2>/dev/null || sed -i -e 's/^MAIL_USERNAME=.*/MAIL_USERNAME=null/g' .env
  sed -i '' -e 's/^MAIL_PASSWORD=.*/MAIL_PASSWORD=null/g' .env 2>/dev/null || sed -i -e 's/^MAIL_PASSWORD=.*/MAIL_PASSWORD=null/g' .env
  sed -i '' -e 's/^MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=no-reply@laravel.ddev.site/g' .env 2>/dev/null || sed -i -e 's/^MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=no-reply@laravel.ddev.site/g' .env
fi

say "✅ Laravel ready → ${URL}"