FROM metasploitframework/metasploit-framework:latest

USER root
WORKDIR /usr/share/metasploit-framework

# copy entrypoint into a well-known absolute location
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/root/.msf4"]

EXPOSE 4444 55553

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["msfconsole"]
