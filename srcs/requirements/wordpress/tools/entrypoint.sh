#!/usr/bin/env sh
set -eu

# ---------------- Env from compose ----------------
: "${DB_HOST:=mariadb}"
: "${DB_NAME:=wordpress}"
: "${DB_USER:=wpuser}"

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${WP_TITLE:=Inception}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"     # must NOT contain 'admin'
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"

# Optional extra user (created if both are set)
: "${WP_USER:=}"
: "${WP_USER_EMAIL:=}"

# ---------------- Secrets (bind mounts) -----------
DB_PASS="$(cat /run/secrets/db_password.txt)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password.txt)"
[ -n "$DB_PASS" ] && [ -n "$ADMIN_PASS" ] || {
  echo "[wp][ERROR] Empty secret value(s) in /run/secrets/*" >&2; exit 1; }

case "$WP_ADMIN_USER" in
  *admin*|*Admin*|*administrator*|*Administrator*)
    echo "[wp][ERROR] WP_ADMIN_USER must not contain 'admin/administrator'." >&2
    exit 1
    ;;
esac

WP_PATH="/var/www/html"
mkdir -p "$WP_PATH"
chown -R www-data:www-data /var/www

as_www() { su -s /bin/sh -c "$*" www-data; }

# ---------------- First-run bootstrap (files) ------------
if [ ! -f "${WP_PATH}/wp-load.php" ]; then
  echo "[wp] Downloading WordPress core..."
  as_www "wp core download --path='${WP_PATH}' --quiet"
fi

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "[wp] Creating wp-config.php..."
  as_www "cd '${WP_PATH}' && wp config create \
    --dbname='${DB_NAME}' \
    --dbuser='${DB_USER}' \
    --dbpass='${DB_PASS}' \
    --dbhost='${DB_HOST}' \
    --skip-check \
    --quiet"

  # Add salts safely (wp-cli handles quoting)
  as_www "cd '${WP_PATH}' && wp config shuffle-salts --quiet"
fi

# ---------------- Wait for DB via PHP file (mysqli) ------
echo "[wp] Waiting for MariaDB with mysqli..."
cat >/tmp/dbwait.php <<'PHP'
<?php
$host = getenv('DB_HOST') ?: 'mariadb';
$user = getenv('DB_USER') ?: 'wpuser';
$pass = trim(@file_get_contents('/run/secrets/db_password.txt'));
$db   = getenv('DB_NAME') ?: 'wordpress';

$ok = false;
for ($i = 0; $i < 60; $i++) {
    $link = @mysqli_connect($host, $user, $pass, $db);
    if ($link) { $ok = true; break; }
    sleep(1);
}
if (!$ok) {
    fwrite(STDERR, "[wp][ERROR] DB not reachable\n");
    exit(1);
}
PHP
php /tmp/dbwait.php
rm -f /tmp/dbwait.php

# ---------------- Install site if needed ---------------
if ! as_www "cd '${WP_PATH}' && wp core is-installed >/dev/null 2>&1"; then
  echo "[wp] Installing site at https://${DOMAIN_NAME} ..."
  as_www "cd '${WP_PATH}' && wp core install \
    --url='https://${DOMAIN_NAME}' \
    --title='${WP_TITLE}' \
    --admin_user='${WP_ADMIN_USER}' \
    --admin_password='${ADMIN_PASS}' \
    --admin_email='${WP_ADMIN_EMAIL}' \
    --skip-email \
    --quiet"
fi

# Optional secondary user (author) — reuses ADMIN_PASS for simplicity
if [ -n "${WP_USER}" ] && [ -n "${WP_USER_EMAIL}" ]; then
  if ! as_www "cd '${WP_PATH}' && wp user get '${WP_USER}' >/dev/null 2>&1"; then
    echo "[wp] Creating user: ${WP_USER}"
    as_www "cd '${WP_PATH}' && wp user create '${WP_USER}' '${WP_USER_EMAIL}' \
      --role=author \
      --user_pass='${ADMIN_PASS}' \
      --quiet"
  fi
fi

# Ensure correct ownership (bind volume can come in as root)
chown -R www-data:www-data "${WP_PATH}"

# ---------------- Run php-fpm (PID 1) -----------
PHPV="$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")"
echo "[wp] Starting php-fpm${PHPV} on :9000 ..."
exec "php-fpm${PHPV}" -F

