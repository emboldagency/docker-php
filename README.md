---
name: PHP on Ubuntu
description: PHP on Ubuntu with MySQL (MariaDB)
tags: [local, docker]
icon: /icon/docker.png
---

# PHP

# Build Process

## Automated Builds

GitHub Actions is configured to automatically build the base images and push the updated templates to Coder when a new version tag is created on GitHub.

New tags will be pushed for each of the versions specified in the [docker-build workflow folder](.github/workflows)

## Manual Builds

```bash
# Set the base image version
export UBUNTU_VERSION=24.04

# Set the ruby version
export PHP_VERSION=8.3

# Build the image
docker build -t emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg PHP_VERSION=${PHP_VERSION} ./build

# Push the image to the registry
docker push emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}
```

## Coder Template Updates

The updated template will be published automatically when a new version tag is created on GitHub.

### Manual Template Updates

Commit and push any changes to git, then do `coder templates push php` to push the template up to Coder.
