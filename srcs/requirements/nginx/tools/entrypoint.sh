#!/usr/bin/env sh
set -eu

: "${DOMAIN_NAME:=vamachad.42.fr}"

CERT_DIR="/etc/nginx/certs"
CRT="${CERT_DIR}/selfsigned.crt"
KEY="${CERT_DIR}/selfsigned.key"

mkdir -p /var/run/nginx

if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
  echo "[nginx] Generating self-signed certificate for CN=${DOMAIN_NAME} ..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=${DOMAIN_NAME}" >/dev/null 2>&1
  chmod 600 "$KEY"
fi

if [ ! -f /etc/nginx/conf.d/site.conf ]; then
  echo "[nginx][ERROR] /etc/nginx/conf.d/site.conf not found (check your bind mount)" >&2
  exit 1
fi

echo "[nginx] Waiting for wordpress:9000 (php-fpm) (max 60s)..."
for i in $(seq 1 60); do
  nc -z wordpress 9000 && break
  sleep 1
done
nc -z wordpress 9000 || {
  echo "[nginx][ERROR] wordpress:9000 unreachable after 60s" >&2
  exit 1
}
echo "[nginx] wordpress:9000 is up."

nginx -t
echo "[nginx] Starting nginx (TLS only) on :443 ..."
exec nginx -g 'daemon off;'

