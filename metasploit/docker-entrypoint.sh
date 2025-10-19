#!/usr/bin/env bash
set -euo pipefail

# Simple logger
log() { printf '%s %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)" "$*" >&2; }

# Defaults (can be overridden via environment / compose)
POSTGRES_HOST="${POSTGRES_HOST:-}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-msf}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msfpass}"
POSTGRES_DB="${POSTGRES_DB:-msf}"
MSFDB_INIT="${MSFDB_INIT:-false}"   # default false to avoid msfdb attempts
MSF_MODE="${MSF_MODE:-console}"     # console | rpc | shell
RPC_USER="${RPC_USER:-msfrpc}"
RPC_PASS="${RPC_PASS:-msfrpcpass}"

MSF_CONF_DIR="/root/.msf4"
DB_YML_PATH="${MSF_CONF_DIR}/database.yml"

wait_for_postgres_tcp() {
  # If pg_isready exists use it; otherwise fallback to simple TCP loop (POSIX shell)
  if command -v pg_isready >/dev/null 2>&1; then
    log "Waiting for Postgres at ${POSTGRES_HOST}:${POSTGRES_PORT} (pg_isready)..."
    until pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" >/dev/null 2>&1; do
      printf '.'
      sleep 1
    done
    echo
    log "Postgres reachable (pg_isready)."
  else
    log "pg_isready missing; performing simple TCP port check for ${POSTGRES_HOST}:${POSTGRES_PORT}..."
    # POSIX tcp test: use /dev/tcp if available
    if [ -e /dev/tcp/"${POSTGRES_HOST}"/"${POSTGRES_PORT}" ] 2>/dev/null; then
      # nothing — some shells support this check directly
      :
    fi
    # fallback loop using bash /dev/tcp (works in busybox/bash)
    until (echo >/dev/tcp/"${POSTGRES_HOST}"/"${POSTGRES_PORT}") >/dev/null 2>&1; do
      printf '.'
      sleep 1
    done
    echo
    log "Postgres TCP port accepting connections."
  fi
}

write_database_yml() {
  mkdir -p "${MSF_CONF_DIR}"
  cat > "${DB_YML_PATH}" <<YML
production:
  adapter: postgresql
  database: ${POSTGRES_DB}
  username: ${POSTGRES_USER}
  password: ${POSTGRES_PASSWORD}
  host: ${POSTGRES_HOST}
  port: ${POSTGRES_PORT}
  pool: 5
  timeout: 5
YML
  log "Wrote ${DB_YML_PATH}"
}

# MAIN

# Don't try to initialize Postgres cluster in this container (this is NOT a DB image)
if [ -n "${POSTGRES_HOST}" ] && [ "${POSTGRES_HOST}" != "localhost" ] && [ "${POSTGRES_HOST}" != "127.0.0.1" ]; then
  # Wait for remote Postgres and write database.yml so msfconsole/bundler/rake know how to connect
  wait_for_postgres_tcp
  write_database_yml

  if [ "${MSFDB_INIT}" = "true" ] || [ "${MSFDB_INIT}" = "1" ]; then
    # Try msfdb init if present but don't fail the container if missing
    log "MSFDB_INIT is true; attempting 'msfdb init' (may not be available in this image)..."
    if command -v msfdb >/dev/null 2>&1; then
      if ! msfdb init; then
        log "msfdb init returned non-zero; continuing."
      fi
    else
      log "msfdb not found; skipping msfdb init."
    fi
  fi
else
  log "POSTGRES_HOST not set or points to localhost; skipping database.yml write and local DB initialization."
fi

# Decide runtime mode
case "${MSF_MODE}" in
  rpc)
    log "Starting msfrpcd (RPC mode) on 0.0.0.0:55553"
    exec msfrpcd -U "${RPC_USER}" -P "${RPC_PASS}" -a 0.0.0.0 -p 55553
    ;;
  shell)
    log "Dropping to interactive shell"
    exec /bin/bash -lc "${@:-/bin/bash}"
    ;;
  console|*)
    log "Starting msfconsole (console mode)"
    exec msfconsole
    ;;
esac
