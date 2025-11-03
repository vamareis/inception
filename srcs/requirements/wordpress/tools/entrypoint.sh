#!/usr/bin/env sh
set -eu

WP_PATH="/var/www/html"

# ---------- Environment ----------
: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${WP_TITLE:=Inception}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

# ---------- Secrets ----------
DB_PASS="$(cat /run/secrets/db_password.txt)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password.txt)"
USER_PASS="$(cat /run/secrets/wp_user_password.txt)"

# ---------- First-time setup ----------
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "[wp] Downloading WordPress core..."
  wp --allow-root core download --path="${WP_PATH}" --quiet

  echo "[wp] Waiting for MariaDB (max 60s)..."
  for i in $(seq 1 60); do
    nc -z mariadb 3306 && break
    sleep 1
  done
  nc -z mariadb 3306 || { echo "[wp][ERROR] MariaDB unreachable after 60s"; exit 1; }

  echo "[wp] Creating wp-config.php..."
  wp --allow-root config create \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="mariadb" \
    --path="${WP_PATH}" \
    --skip-check --quiet

  echo "[wp] Installing WordPress..."
  wp --allow-root core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --path="${WP_PATH}" \
    --skip-email --quiet

  echo "[wp] Creating non-admin user: ${WP_USER}"
  wp --allow-root user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --role=subscriber \
    --user_pass="${USER_PASS}" \
    --path="${WP_PATH}" \
    --quiet
fi

PHPV="$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")"
echo "[wp] Starting php-fpm${PHPV} on :9000 ..."
exec "php-fpm${PHPV}" -F

