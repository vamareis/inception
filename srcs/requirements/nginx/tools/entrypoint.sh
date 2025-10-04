#!/usr/bin/env sh
set -eu

# DOMAIN_NAME is optional; used only as the certificate CN
: "${DOMAIN_NAME:=localhost}"

CERT_DIR="/etc/nginx/certs"
CRT="${CERT_DIR}/selfsigned.crt"
KEY="${CERT_DIR}/selfsigned.key"

# Ensure runtime dirs exist
mkdir -p /var/run/nginx

# Generate a self-signed certificate if missing
if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
  echo "[nginx] Generating self-signed certificate for CN=${DOMAIN_NAME} ..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=${DOMAIN_NAME}" >/dev/null 2>&1
  chmod 600 "$KEY"
fi

# Ensure the vhost config was mounted
if [ ! -f /etc/nginx/conf.d/site.conf ]; then
  echo "[nginx][ERROR] /etc/nginx/conf.d/site.conf not found (check your bind mount)" >&2
  exit 1
fi

# Sanity-check configuration, then start in foreground (PID 1)
nginx -t
echo "[nginx] Starting nginx (TLS only) on :443 ..."
exec nginx -g 'daemon off;'

