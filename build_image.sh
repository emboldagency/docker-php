#!/usr/bin/env bash

# Stop script on first error
set -e

# --- Configuration ---
REGISTRY_HOST="ghcr.io"
REGISTRY_USER="emboldagency"
IMAGE_NAME="docker-php"
DEFAULT_UBUNTU="24.04"
DEFAULT_PHP="8.3"
# Default tag will be: 8.3-ubuntu24.04-local
# DEFAULT_TAG_SUFFIX="local"

# --- Helper Functions ---
cyan="\033[0;36m"
green="\033[0;32m"
reset="\033[0m"

echo_info() { echo -e "${cyan}$1${reset}"; }
echo_success() { echo -e "${green}$1${reset}"; }

prompt_var() {
	local var="$1"
	local prompt="$2"
	local default="$3"

	# If env var is already set, use it
	if [ -n "${!var}" ]; then return; fi

	read -rp "$prompt [$default]: " val
	if [ -z "$val" ]; then
		export "$var"="$default"
	else
		export "$var"="$val"
	fi
}

# --- Main Script ---

echo_info "--- Local Docker PHP Build Helper ---"

# 1. Gather Inputs
prompt_var UBUNTU_VERSION "Enter Ubuntu version" "$DEFAULT_UBUNTU"
prompt_var PHP_VERSION "Enter PHP version" "$DEFAULT_PHP"
prompt_var TAG_SUFFIX "Enter tag suffix (optional)" ""

# 2. Construct the Tag
# Format: 8.3-ubuntu24.04[-suffix]
BASE_TAG="${PHP_VERSION}-ubuntu${UBUNTU_VERSION}"

if [ -n "$TAG_SUFFIX" ]; then
	FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${BASE_TAG}-${TAG_SUFFIX}"
else
	FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${BASE_TAG}"
fi

echo
echo "Building Image:"
echo "  TAG:     $FULL_IMAGE_TAG"
echo "  UBUNTU:  $UBUNTU_VERSION"
echo "  PHP:     $PHP_VERSION"
echo

# 3. Build
# We use DOCKER_BUILDKIT=1 for caching
# We point to build/Dockerfile but use the ROOT context (.) to match GHA
DOCKER_BUILDKIT=1 docker build -t "$FULL_IMAGE_TAG" \
	--build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
	--build-arg PHP_VERSION="${PHP_VERSION}" \
	--target final \
	./build

echo
echo_success "Build Complete!"
echo "To run this image interactively:"
echo "  docker run --rm -it --entrypoint /bin/bash $FULL_IMAGE_TAG"
echo

# 4. Optional Push
read -rp "Do you want to push '$FULL_IMAGE_TAG' to GHCR? [y/N]: " push_confirm
if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
	echo_info "Pushing..."
	docker push "$FULL_IMAGE_TAG"
	echo_success "Pushed successfully."
else
	echo "Skipping push."
fi
