#!/bin/bash
set -euo pipefail

ENV_FILE="${1:-}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env not found at: $ENV_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"

SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

umask 177

pick_len() {
  if command -v shuf >/dev/null 2>&1; then
    shuf -i 8-15 -n 1
  else
    echo 8
  fi
}

rand() {
  local len; len="$(pick_len)"
    tr -dc 'A-Za-z0-9!@#%^&*()_+=' </dev/urandom | head -c "$len" || true
}

mksecret() {
  local path="$1"
  [[ -s "$path" ]] || rand >"$path"
}

mksecret "$SECRETS_DIR/db_root_password.txt"
mksecret "$SECRETS_DIR/db_password.txt"
mksecret "$SECRETS_DIR/wp_admin_password.txt"
mksecret "$SECRETS_DIR/wp_user_password.txt"

LOGIN="$(id -un)"
DATA_BASE="/home/$LOGIN/data"
mkdir -p "$DATA_BASE/db" "$DATA_BASE/wp"

printf "Secrets ready in %s\n" "$SECRETS_DIR"
printf "Data dirs ready at %s/{db,wp}\n" "$DATA_BASE"

