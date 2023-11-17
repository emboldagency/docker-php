---
name: PHP 8.1 on Ubuntu 22.04
description: PHP 8.1 on Ubuntu 22.04 with mysql
tags: [local, docker]
icon: /icon/docker.png
---

# PHP 8.1 on Ubuntu 22.04

## Getting started

Clone the repo.

Commit and push any changes to git, then do `coder templates push php81-ubuntu2204` to push the template up to Coder.

# Updating the image

Autobuilds are turned on in Dockerhub whenever the branch has a new commit or docker-base gets updated.

If you need to build/push manually:

Run `docker build -t registry.embold.app/php:8.1-ubuntu22.04 ./build` to build the image

Run `docker push registry.embold.app/php8.1-ubuntu22.04` to push the image to Docker Hub
