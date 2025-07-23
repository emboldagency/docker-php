ARG MARIADB_VERSION
FROM mariadb:${MARIADB_VERSION} AS base

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    ca-certificates \
    curl && \
    rm -rf /var/lib/apt/lists/*
