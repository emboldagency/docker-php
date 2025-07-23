ARG POSTGRES_VERSION
FROM postgres:${POSTGRES_VERSION} AS base

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    ca-certificates \
    curl && \
    rm -rf /var/lib/apt/lists/*
