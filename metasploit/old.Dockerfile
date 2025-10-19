# metasploit/Dockerfile - Metasploit + embedded Postgres
FROM metasploitframework/metasploit-framework:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/metasploit

# Install PostgreSQL client & server utilities and pg_isready (if not present)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      postgresql \
      postgresql-contrib \
      libpq-dev \
      && apt-get clean && rm -rf /var/lib/apt/lists/*

# copy entrypoint script and make executable
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/lib/postgresql/data", "/root/.msf4"]
EXPOSE 4444 55553

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["msfconsole"]
