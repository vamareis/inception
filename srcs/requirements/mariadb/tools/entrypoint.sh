#!/usr/bin/env sh
set -eu

# ---- From .env (with safe defaults) ----
DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-wpuser}"

# Keep DB names boring so we don't need quoting in SQL
case "$DB_NAME" in
  ''|*[!A-Za-z0-9_]*)
    echo "[mariadb][ERROR] MYSQL_DATABASE must match [A-Za-z0-9_]+; got: '$DB_NAME'" >&2
    exit 1;;
esac

case "$DB_USER" in
  ''|*[!A-Za-z0-9_]*)
    echo "[mariadb][ERROR] MYSQL_USER must match [A-Za-z0-9_]+; got: '$DB_USER'" >&2
    exit 1;;
esac

# ---- Secrets (mounted by compose) ----
DB_ROOT_PASS="$(cat /run/secrets/db_root_password.txt)"
DB_PASS="$(cat /run/secrets/db_password.txt)"
[ -n "$DB_ROOT_PASS" ] && [ -n "$DB_PASS" ] || {
  echo "[mariadb][ERROR] Empty secret value." >&2; exit 1; }

# ---- Runtime/data dirs ----
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# ---- First run? Initialize & bootstrap using a temp server ----
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[mariadb] First run: initializing datadir..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql

  echo "[mariadb] Starting temporary server (socket-only)..."
  mysqld --user=mysql \
         --skip-networking \
         --socket=/run/mysqld/mysqld.sock \
         --datadir=/var/lib/mysql \
         --pid-file=/run/mysqld/mysqld.pid &

  # Wait up to ~60s until it pings
  for i in $(seq 1 60); do
    if mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
      break
    fi
    sleep 1
    [ "$i" -eq 60 ] && { echo "[mariadb][ERROR] temp mysqld did not become ready"; exit 1; }
  done

  echo "[mariadb] Bootstrap SQL..."
  mysql --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';

CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
SQL

  echo "[mariadb] Stopping temporary server..."
  mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot -p"${DB_ROOT_PASS}" shutdown
else
  echo "[mariadb] Existing datadir detected — skipping init."
fi

echo "[mariadb] Starting real mysqld..."
exec mysqld --user=mysql --console

