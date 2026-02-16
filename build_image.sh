#!/usr/bin/env bash

# Stop script on first error
set -e

# --- Configuration ---
REGISTRY_HOST="ghcr.io"
REGISTRY_USER="emboldagency"
IMAGE_NAME="docker-php"
DEFAULT_OS_TYPE="ubuntu"
DEFAULT_UBUNTU="24.04"
DEFAULT_ALPINE="3.20"
DEFAULT_PHP="8.3"

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
prompt_var OS_TYPE "Enter OS Type (ubuntu/alpine)" "$DEFAULT_OS_TYPE"
prompt_var PHP_VERSION "Enter PHP version" "$DEFAULT_PHP"

if [[ "$OS_TYPE" == "alpine" ]]; then
    prompt_var ALPINE_VERSION "Enter Alpine version" "$DEFAULT_ALPINE"
    OS_TAG="alpine${ALPINE_VERSION}"
    DOCKERFILE_PATH="./build/Dockerfile.alpine"
    PHP_VERSION_DOTLESS="${PHP_VERSION//./}"
    DEFAULT_BASE="ghcr.io/emboldagency/docker-base:alpine${ALPINE_VERSION}"
else
    prompt_var UBUNTU_VERSION "Enter Ubuntu version" "$DEFAULT_UBUNTU"
    OS_TAG="ubuntu${UBUNTU_VERSION}"
    DOCKERFILE_PATH="./build/Dockerfile"
    DEFAULT_BASE="ghcr.io/emboldagency/docker-base:ubuntu${UBUNTU_VERSION}"
fi

prompt_var BASE_IMAGE "Enter Base Image" "$DEFAULT_BASE"
prompt_var TAG_SUFFIX "Enter tag suffix (optional)" ""

# 2. Construct the Tag
BASE_TAG="${PHP_VERSION}-${OS_TAG}"

if [ -n "$TAG_SUFFIX" ]; then
    FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${BASE_TAG}-${TAG_SUFFIX}"
    TAG_SUFFIX_ARG="-${TAG_SUFFIX}"
else
    FULL_IMAGE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${BASE_TAG}"
    TAG_SUFFIX_ARG=""
fi

echo
echo "Building Image:"
echo "  TAG:     $FULL_IMAGE_TAG"
echo "  BASE:    $BASE_IMAGE"
echo "  OS:      $OS_TYPE ($OS_TAG)"
echo "  PHP:     $PHP_VERSION"
if [[ "$OS_TYPE" == "alpine" ]]; then
    echo "  DOTLESS: $PHP_VERSION_DOTLESS"
fi
echo "  FILE:    $DOCKERFILE_PATH"
echo

# 3. Build
if [ ! -f "$DOCKERFILE_PATH" ] && [[ "$OS_TYPE" == "alpine" ]]; then
    echo "Error: Alpine Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

# Logic to force local image:
# 1. We use --pull=false
# 2. We check if the image exists locally. If it does, we assume the user wants to use that.
# 3. If it doesn't exist locally and starts with ghcr.io, we let it try to pull.
PULL_POLICY="--pull"
if docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
    echo_info "Using local image: $BASE_IMAGE"
    PULL_POLICY="--pull=false"
else
    if [[ "$BASE_IMAGE" != ghcr.io* ]]; then
        echo "Error: Base image '$BASE_IMAGE' not found locally and is not a remote registry path."
        exit 1
    fi
    echo_info "Base image not found locally, will attempt to pull: $BASE_IMAGE"
fi

if [[ "$OS_TYPE" == "alpine" ]]; then
    DOCKER_BUILDKIT=1 docker build -t "$FULL_IMAGE_TAG" \
        -f "$DOCKERFILE_PATH" \
        $PULL_POLICY \
        --build-arg BASE_IMAGE="${BASE_IMAGE}" \
        --build-arg ALPINE_VERSION="${ALPINE_VERSION}" \
        --build-arg PHP_VERSION_DOTLESS="${PHP_VERSION_DOTLESS}" \
        --build-arg TAG_SUFFIX="${TAG_SUFFIX_ARG}" \
        --target final \
        ./build
else
    DOCKER_BUILDKIT=1 docker build -t "$FULL_IMAGE_TAG" \
        -f "$DOCKERFILE_PATH" \
        $PULL_POLICY \
        --build-arg BASE_IMAGE="${BASE_IMAGE}" \
        --build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
        --build-arg PHP_VERSION="${PHP_VERSION}" \
        --build-arg TAG_SUFFIX="${TAG_SUFFIX_ARG}" \
        --target final \
        ./build
fi

echo
echo_success "Build Complete!"
echo "To run this image interactively:"
if [[ "$OS_TYPE" == "alpine" ]]; then
    echo "  docker run --rm -it --entrypoint /bin/zsh $FULL_IMAGE_TAG"
else
    echo "  docker run --rm -it --entrypoint /bin/bash $FULL_IMAGE_TAG"
fi
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