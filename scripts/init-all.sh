#!/bin/sh
set -eu
# init-all.sh — full stack initializer (Laravel + Moodle)
SKIP_LARAVEL=0
SKIP_MOODLE=0
TEST_MAIL=0
for a in "${@}"; do
  case "$a" in
    --skip-laravel) SKIP_LARAVEL=1 ;;
    --skip-moodle)  SKIP_MOODLE=1 ;;
    --test-mail)    TEST_MAIL=1 ;;
  esac
done

say(){ printf '%s\n' "[init-all] $*"; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# Laravel
if [ "$SKIP_LARAVEL" -eq 0 ]; then
  say "Initializing Laravel…"
  "$ROOT/scripts/init-ddev-laravel.sh"
  L="$ROOT/apps/laravel"
  [ -f "$L/.env" ] || cp "$L/.env.example" "$L/.env" 2>/dev/null || true
  perl -i -pe 's/^APP_URL=.*/APP_URL=https:\/\/laravel.ddev.site/;
               s/^MAIL_MAILER=.*/MAIL_MAILER=smtp/;
               s/^MAIL_HOST=.*/MAIL_HOST=localhost/;
               s/^MAIL_PORT=.*/MAIL_PORT=1025/;
               s/^MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=null/;
               s/^MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=no-reply\@laravel.ddev.site/;' "$L/.env"
  (cd "$L" && ddev artisan migrate --force || true)
  [ "$TEST_MAIL" -eq 1 ] && (cd "$L" && ddev artisan tinker --execute=\"Mail::raw('hello',fn($m)=>$m->to('test@example.com')->subject('Mailpit OK'));\" || true)
fi

# Moodle
if [ "$SKIP_MOODLE" -eq 0 ]; then
  say "Initializing Moodle…"
  "$ROOT/scripts/init-ddev-moodle.sh"
fi

say "✅ All projects ready."