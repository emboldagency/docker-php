---
name: PHP on Ubuntu 22.04
description: PHP on Ubuntu 22.04 with mysql
tags: [local, docker]
icon: /icon/docker.png
---

# PHP on Ubuntu 22.04

## Getting started

Clone the repo.

Commit and push any changes to git, then do `coder templates push php-ubuntu2204` to push the template up to Coder.

# Updating the image

The docker image should build automatically at startup if there are any changes.

If you need to build/push manually:

Run `docker build -t registry.embold.app/php:${PHP_VERSION}-ubuntu22.04 ./build` to build the image

Run `docker push registry.embold.app/php${PHP_VERSION}-ubuntu22.04` to push the image to Docker Hub
