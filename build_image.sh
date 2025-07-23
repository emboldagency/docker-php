#!/usr/bin/env bash

# Prompt for missing environment variables
prompt_var() {
  local var="$1"
  local prompt="$2"
  if [ -z "${!var}" ]; then
    read -rp "$prompt: " val
    export "$var"="$val"
  fi
}

prompt_var GH_PACKAGES_TOKEN "Enter your GitHub Packages token (PAT with read:packages scope)"
prompt_var GH_USERNAME "Enter your GitHub username"
prompt_var UBUNTU_VERSION "Enter Ubuntu version (e.g. 24.04)"
prompt_var PHP_VERSION "Enter PHP version (e.g. 8.3)"
prompt_var TEMPLATE_VERSION "Enter template version (e.g. 1.7.0)"

red="\033[0;31m"
cyan="\033[0;36m"
reset="\033[0m"

echo_error() {
    echo -e "${red}Error: $1${reset}"
    exit 1
}

echo_highlight() {
    echo -e "${cyan}$1${reset}"
}

# Build the image
DOCKER_BUILDKIT=1 docker build -t emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}-release${TEMPLATE_VERSION} \
  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
  --build-arg PHP_VERSION=${PHP_VERSION} \
  --build-arg GH_USERNAME=${GH_USERNAME} \
  --secret id=GH_PACKAGES_TOKEN,env=GH_PACKAGES_TOKEN ./build

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo_error "Build failed. Please check the output for errors."
  exit 1
fi

echo "To push the image, run:"
echo_highlight "  docker push emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}-release${TEMPLATE_VERSION}"

read -rp "Do you want to push the image now? [y/N]: " push_answer
if [[ "$push_answer" =~ ^[Yy]$ ]]; then
  docker push emboldcreative/php:${PHP_VERSION}-ubuntu${UBUNTU_VERSION}-release${TEMPLATE_VERSION}
fi