# kali/Dockerfile
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nmap \
      netcat-openbsd \
      curl \
      python3 \
      python3-pip \
      iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /root
ENTRYPOINT ["/bin/bash"]
