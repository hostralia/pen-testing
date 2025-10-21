# metasploit/Dockerfile
FROM metasploitframework/metasploit-framework:latest

USER root
WORKDIR /usr/share/metasploit-framework

# Create a small entrypoint that waits for the DB and writes database.yml
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    cat > /usr/local/bin/metasploit-entrypoint.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

POSTGRES_HOST="${POSTGRES_HOST:-kali}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-msf}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msfpass}"
POSTGRES_DB="${POSTGRES_DB:-msf}"
MSFDB_INIT="${MSFDB_INIT:-false}"
MSF_MODE="${MSF_MODE:-console}"

MSF_CONF_DIR="/root/.msf4"
DB_YML_PATH="${MSF_CONF_DIR}/database.yml"

# wait for TCP port to be open
wait_for_tcp() {
  host="$1"; port="$2"
  printf 'Waiting for %s:%s...' "$host" "$port" >&2
  until (echo > /dev/tcp/"${host}"/"${port}") >/dev/null 2>&1; do
    printf '.' >&2
    sleep 1
  done
  printf " ok\n" >&2
}

write_db_yml() {
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
  printf "Wrote %s\n" "${DB_YML_PATH}" >&2
}

# If POSTGRES_HOST appears set to a non-local target, wait and write file
if [ -n "${POSTGRES_HOST}" ] && [ "${POSTGRES_HOST}" != "localhost" ] && [ "${POSTGRES_HOST}" != "127.0.0.1" ]; then
  wait_for_tcp "${POSTGRES_HOST}" "${POSTGRES_PORT}"
  write_db_yml

  if [ "${MSFDB_INIT}" = "true" ] || [ "${MSFDB_INIT}" = "1" ]; then
    if command -v msfdb >/dev/null 2>&1; then
      msfdb init || echo "msfdb init returned non-zero, continuing"
    else
      echo "msfdb not found, skipping" >&2
    fi
  fi
else
  echo "POSTGRES_HOST is not configured for an external DB; skipping database.yml" >&2
fi

case "${MSF_MODE}" in
  rpc)
    exec msfrpcd -U msfrpc -P msfrpcpass -a 0.0.0.0 -p 55553
    ;;
  shell)
    exec /bin/bash -lc "${@:-/bin/bash}"
    ;;
  console|*)
    exec msfconsole
    ;;
esac
EOF
    ; \
    chmod +x /usr/local/bin/metasploit-entrypoint.sh

VOLUME ["/root/.msf4"]
EXPOSE 4444 55553

ENTRYPOINT ["/usr/local/bin/metasploit-entrypoint.sh"]
CMD ["msfconsole"]
