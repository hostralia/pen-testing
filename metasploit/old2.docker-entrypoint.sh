#!/usr/bin/env bash
set -euo pipefail

# Helper: print to stderr
err() { printf '%s\n' "$*" >&2; }

# Defaults (override with env)
POSTGRES_HOST="${POSTGRES_HOST:-}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-msf}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msfpass}"
POSTGRES_DB="${POSTGRES_DB:-msf}"
MSFDB_INIT="${MSFDB_INIT:-false}"   # default false - safer
MSF_MODE="${MSF_MODE:-console}"     # console | rpc | shell
RPC_USER="${RPC_USER:-msfrpc}"
RPC_PASS="${RPC_PASS:-msfrpcpass}"

MSF_CONF_DIR="/root/.msf4"
DB_YML_PATH="${MSF_CONF_DIR}/database.yml"

wait_for_postgres() {
  # Use docker-provided pg_isready if present; fallback to simple tcp check
  if command -v pg_isready >/dev/null 2>&1; then
    err "Waiting for postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
    until pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" >/dev/null 2>&1; do
      printf '.'
      sleep 1
    done
    echo
    err "Postgres is ready."
    return 0
  else
    # fallback: simple netcat or bash tcp-check
    err "pg_isready missing; performing simple TCP check..."
    while ! (echo > /dev/tcp/"${POSTGRES_HOST}"/"${POSTGRES_PORT}") >/dev/null 2>&1; do
      printf '.'
      sleep 1
    done
    echo
    err "Postgres TCP port is accepting connections."
    return 0
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
  err "Wrote ${DB_YML_PATH}"
}

# MAIN

# Protect: never try to init a DB cluster locally in this container
# If POSTGRES_HOST is empty or points to localhost, we avoid trying to initialize postgres here.
if [ -z "${POSTGRES_HOST}" ] || [ "${POSTGRES_HOST}" = "localhost" ] || [ "${POSTGRES_HOST}" = "127.0.0.1" ]; then
  err "POSTGRES_HOST is unset or points to localhost (value='${POSTGRES_HOST}')."
  err "This container will NOT initialize a Postgres cluster. If you want an external DB, set POSTGRES_HOST to your postgres service name."
else
  # Wait for remote Postgres to be reachable, then write database.yml
  wait_for_postgres
  write_database_yml

  if [ "${MSFDB_INIT}" = "true" ] || [ "${MSFDB_INIT}" = "1" ]; then
    # Try msfdb init but ignore non-fatal failures (msfdb can use system services which may not exist in container)
    err "Attempting msfdb init (may print warnings)."
    if ! msfdb init; then
      err "msfdb init returned a non-zero exit; continuing (check database.yml and postgres logs if DB not usable)."
    fi
  fi
fi

# Decide what to run
case "${MSF_MODE}" in
  rpc)
    err "Starting msfrpcd on 0.0.0.0:55553"
    exec msfrpcd -U "${RPC_USER}" -P "${RPC_PASS}" -a 0.0.0.0 -p 55553
    ;;
  shell)
    exec /bin/bash -lc "${@:-/bin/bash}"
    ;;
  console|*)
 #   err "Starting msfconsole"
  #  exec msfconsole
    ;;
esac
