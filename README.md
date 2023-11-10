---
name: PHP 8.1 on Ubuntu 22.04
description: PHP 8.1 on Ubuntu 22.04 with mysql
tags: [local, docker]
icon: /icon/docker.png
---

# PHP 8.1 on Ubuntu 22.04

## Getting started

Run `coder templates pull php81-ubuntu2204`

Commit any changes to git, then do `coder templates push php81-ubuntu2204` to push the template up to Coder.

# Updating the image

Run `docker build -t emboldcreative/php:8.1-ubuntu22.04 ./build` to build the image

Run `docker push emboldcreative/php8.1-ubuntu22.04` to push the image to Docker Hub
