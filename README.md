---
name: PHP on Ubuntu
description: PHP on Ubuntu with MySQL (MariaDB)
tags: [local, docker]
icon: /icon/docker.png
---

# PHP

[![Build and Deploy](https://github.com/emboldagency/docker-php/actions/workflows/build-and-deploy.yml/badge.svg)](https://github.com/emboldagency/docker-php/actions/workflows/build-and-deploy.yml) <!--
-->![Semantic Versioning](https://img.shields.io/badge/semver-2.0.0-green?logo=semver)

# Build Process

## Automated Builds

GitHub Actions is configured to:

- automatically build and push the base images to GHCR
- push the updated templates to Coder when a new version tag is created on GitHub

The jobs are defined in [build-and-deploy.yml](.github/workflows/build-and-deploy.yml)

### GitHub Actions Manual Run

You can also start the GitHub Actions workflow manually using the [GitHub CLI](https://cli.github.com/).

```bash
# Optionally set the reference branch, commit SHA, or tag for the workflow run (e.g., main, v2.0.1, f74efaac558c7f0dcda915d23ef5387942341cb2)
export REFERENCE="main"

# Optionally set the skip jobs field to a comma separated list of jobs to skip.
# See [build-and-deploy.yml](.github/workflows/build-and-deploy.yml)
export SKIP_JOBS="build-and-push-docker"

gh workflow run build-and-deploy.yml --ref $REFERENCE --field skip-jobs=$SKIP_JOBS
```

## Manual Builds

### Using the Build Script (Recommended)

For local development and testing, use the included helper script. It prompts for the Ubuntu & PHP versions and an optional tag suffix, then runs the build with the correct arguments.

```bash
./build_image.sh
```

### Using Docker CLI

Set the base image version and PHP version

```bash
export UBUNTU_VERSION=24.04
export PHP_VERSION=8.3
```

Build the image

```bash
docker buildx build \
  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
  --build-arg PHP_VERSION=${PHP_VERSION} \
  -t ghcr.io/emboldagency/docker-php:{PHP_VERSION}-ubuntu${UBUNTU_VERSION} \
  --load \
  ./build
```

If you are pushing to GHCR, authenticate first.

- The username is the owner of the PAT.
- The password is in Bitwarden on the `GitHub (Alert/Staging)` entry as `GHCR Token (Write)`.

```bash
export GHCR_USER="emboldagency"
export GHCR_TOKEN="<your-ghcr-pat-with-packages-write>"
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
```

Push the image to the registry

```bash
docker push ghcr.io/emboldagency/docker-php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}
```

## Coder Template Updates

The updated template will be published automatically when a new version tag is created on GitHub.

To manually run the job without pushing a release tag, or to skip the build step, see: [GitHub Actions Manual Run](#github-actions-manual-run)

### Manual Template Updates

Commit and push any changes to git, then do `coder templates push php` to push the template up to Coder.
