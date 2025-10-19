FROM metasploitframework/metasploit-framework:latest
USER root
WORKDIR /opt/metasploit
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh || true
VOLUME ["/root/.msf4"]
EXPOSE 4444 55553
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["msfconsole"]
