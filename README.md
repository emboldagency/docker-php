---
name: PHP 8.1 Ubuntu 22.04
description: PHP 8.1 Ubuntu 22.04 with mysql
tags: [local, docker]
icon: /icon/docker.png
---

# PHP 8.1 Ubuntu 22.04

## Getting started

Run `coder templates pull php8.1-ubuntu22.04`

Commit any changes to git, then do `coder templates push` from the directory with `main.tf` to push the image up to Coder.

# Rebuilding the image

Run `docker build -t emboldagency/php:8.1-ubuntu22.04` to build the image

Run `docker push emboldagency/php8.1-ubuntu22.04` to push the image to Docker Hub