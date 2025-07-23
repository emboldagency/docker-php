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
- automatically build and push the base images to DockerHub 
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

To build with the `pulsar-embold` gem from GitHub Packages, you need a GitHub personal access token (PAT) with `read:packages` scope. Set it as an environment variable before building.

You can retrieve the token from the Bitwarden CLI and set it as an environment variable:
```bash
export GH_PACKAGES_TOKEN=$(bw get item "Github (Alert/Staging)" | jq -r '.fields[] | select(.name=="GitHub Package Repository Token (Read)") | .value')
```
Or, if you prefer to use the Bitwarden item ID, for example if the entry name ever changes:
```bash
export GH_PACKAGES_TOKEN=$(bw get item ee4811bc-0070-4c98-b1d5-abcb012e166c | jq -r '.fields[] | select(.name=="GitHub Package Repository Token (Read)") | .value')
```
If you don't use Bitwarden CLI, set your token directly:
```bash
export GH_PACKAGES_TOKEN=ghp_yourtokenhere
```

Set the build parameters (use your values or keep the defaults):
```bash
export UBUNTU_VERSION=24.04
export PHP_VERSION=8.3
export TEMPLATE_VERSION=1.7.0
export GH_USERNAME=emboldagency # or your GitHub username
```

### Build Options

**Option 1: Use the build script**
```bash
./build_image.sh
```

**Option 2: Run the build manually**
```bash
DOCKER_BUILDKIT=1 docker build -t emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}-release${TEMPLATE_VERSION} \
  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
  --build-arg PHP_VERSION=${PHP_VERSION} \
  --build-arg GH_USERNAME=${GH_USERNAME} \
  --secret id=GH_PACKAGES_TOKEN,env=GH_PACKAGES_TOKEN ./build
```

**Push the image to the registry:**
```bash
docker push emboldcreative/php:${PHP_VERSION}
```

## Coder Template Updates

The updated template will be published automatically when a new version tag is created on GitHub.

To manually run the job without pushing a release tag, or to skip the build step, see: [GitHub Actions Manual Run](#github-actions-manual-run)

### Manual Template Updates

Commit and push any changes to git, then do `coder templates push php` to push the template up to Coder.

Note: During testing, you can set `--activate=false` to push the template without marking it as the latest version, so new workspaces won't be prompted to update.
