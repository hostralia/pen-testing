# kali/Dockerfile
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV PGDATA=/var/lib/postgresql/data/pgdata

# Install Postgres and some useful tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      postgresql postgresql-contrib \
      iproute2 netcat-openbsd curl python3 python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add an entrypoint script that initializes Postgres on first run and starts it (foreground)
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    cat > /usr/local/bin/kali-entrypoint.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PGDATA="${PGDATA:-/var/lib/postgresql/data/pgdata}"
POSTGRES_USER="${POSTGRES_USER:-msf}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msfpass}"
POSTGRES_DB="${POSTGRES_DB:-msf}"

mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA" || true
chmod 700 "$PGDATA" || true

# initialize if empty
if [ ! -f "${PGDATA}/PG_VERSION" ]; then
  echo "Initializing Postgres database cluster at ${PGDATA}..."
  su -s /bin/bash postgres -c "initdb -D '${PGDATA}'" || true

  # start temporary server to create user & db
  su -s /bin/bash postgres -c "pg_ctl -D '${PGDATA}' -o '-c listen_addresses=127.0.0.1' -w start"

  su -s /bin/bash postgres -c "psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
    CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
    CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
EOSQL"

  su -s /bin/bash postgres -c "pg_ctl -D '${PGDATA}' -m fast -w stop"
  echo "Postgres initialized."
fi

echo "Starting Postgres (foreground) listening on all interfaces..."
# run postgres as the container PID 1
exec su -s /bin/bash postgres -c "postgres -D '${PGDATA}' -c listen_addresses='*'"
EOF
    ; \
    chmod +x /usr/local/bin/kali-entrypoint.sh

VOLUME ["/var/lib/postgresql/data/pgdata","/root"]
WORKDIR /root

ENTRYPOINT ["/usr/local/bin/kali-entrypoint.sh"]
CMD ["/bin/bash"]
