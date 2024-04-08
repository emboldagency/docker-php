---
name: PHP on Ubuntu
description: PHP on Ubuntu with MySQL (MariaDB)
tags: [local, docker]
icon: /icon/docker.png
---

# PHP

## Getting started

Clone the repo.

Commit and push any changes to git, then do `coder templates push php` to push the template up to Coder.

# Updating the image

```
# Set the base image version
export UBUNTU_VERSION=22.04

# Set the ruby version
export PHP_VERSION=8.1

# Build the image
docker build -t emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg PHP_VERSION=${PHP_VERSION} ./build

# Push the image to the registry
docker push emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}
```
