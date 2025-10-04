#!/bin/bash
set -euo pipefail

# --- Args & preflight ---------------------------------------------------------
ENV_FILE="${1:-}"
if [[ -z "$ENV_FILE" ]]; then
  echo "usage: $0 <path-to-.env>" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env not found at: $ENV_FILE" >&2
  exit 1
fi

# Compute repo root from this script's location (no git required)
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"

# --- Secrets (idempotent) -----------------------------------------------------
SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

# New files created from now on get 600 perms (umask 177)
umask 177

pick_len() {  # random integer in [8,15]
  if command -v shuf >/dev/null 2>&1; then
    shuf -i 8-15 -n 1
  else
    echo 8
  fi
}

rand() {      # prints a random printable string of length ∈ [8,15]
  local len; len="$(pick_len)"
    tr -dc 'A-Za-z0-9!@#%^&*()_+=' </dev/urandom | head -c "$len" || true
}

mksecret() {  # mksecret <path>  (create only if missing/empty)
  local path="$1"
  [[ -s "$path" ]] || rand >"$path"
}

mksecret "$SECRETS_DIR/db_root_password.txt"
mksecret "$SECRETS_DIR/db_password.txt"
mksecret "$SECRETS_DIR/credentials.txt"

# --- Host bind directories ----------------------------------------------------
LOGIN="$(id -un)"
DATA_BASE="/home/$LOGIN/data"
mkdir -p "$DATA_BASE/db" "$DATA_BASE/wp"

# --- Done ---------------------------------------------------------------------
printf "Secrets ready in %s\n" "$SECRETS_DIR"
printf "Data dirs ready at %s/{db,wp}\n" "$DATA_BASE"

