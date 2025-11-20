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

DEFAULT_UBUNTU_VERSION=24.04
DEFAULT_PHP_VERSION=8.3
DEFAULT_TEMPLATE_VERSION=1.6.3

# Default values (match the examples shown to allow Continue with Enter)
: ${UBUNTU_VERSION:=$DEFAULT_UBUNTU_VERSION}
: ${PHP_VERSION:=$DEFAULT_PHP_VERSION}
: ${TEMPLATE_VERSION:=$DEFAULT_TEMPLATE_VERSION}

# Prompt for values but show the default and accept Enter to keep it.
prompt_var() {
	local var="$1"
	local prompt="$2"
	# current value (may come from env or defaults above)
	local current="${!var}"
	read -rp "$prompt [$current]: " val
	if [ -n "$val" ]; then
		export "$var"="$val"
	else
		export "$var"="$current"
	fi
}

prompt_var UBUNTU_VERSION "Enter Ubuntu version"
prompt_var PHP_VERSION "Enter PHP version"
prompt_var TEMPLATE_VERSION "Enter template version"

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

# Show the values to be used
echo_highlight "The following values will be used to build the image:"
echo "  UBUNTU_VERSION:    $UBUNTU_VERSION"
echo "  PHP_VERSION:       $PHP_VERSION"
echo "  TEMPLATE_VERSION:  $TEMPLATE_VERSION"
echo

read -rp "Proceed with these values? [Y/n]: " confirm
if [[ ! (-z "$confirm" || "$confirm" =~ ^[Yy]$) ]]; then
	echo_error "Aborted. To avoid prompts, export the required environment variables before running this script:"
	echo "  export UBUNTU_VERSION=$DEFAULT_UBUNTU_VERSION"
	echo "  export PHP_VERSION=$DEFAULT_PHP_VERSION"
	echo "  export TEMPLATE_VERSION=$DEFAULT_TEMPLATE_VERSION"
	exit 1
fi

# --- Tag Generation ---
# Registry settings (switching to GHCR)
readonly REGISTRY_HOST="ghcr.io"
readonly REGISTRY_USER="emboldagency"
readonly IMAGE_NAME="php"

# Define version suffixes
readonly VERSION_SUFFIX="${PHP_VERSION}-ubuntu${UBUNTU_VERSION}"
readonly RELEASE_SUFFIX="${VERSION_SUFFIX}-release${TEMPLATE_VERSION}"

# Define final, full image tags
readonly GENERAL_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${VERSION_SUFFIX}"
readonly RELEASE_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${RELEASE_SUFFIX}"

# Build the image
DOCKER_BUILDKIT=1 docker build -t "$RELEASE_TAG" \
	--build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
	--build-arg PHP_VERSION=${PHP_VERSION} \
	--target final \
	./build

# Check if the build was successful
if [ $? -ne 0 ]; then
	echo_error "Build failed. Please check the output for errors."
	exit 1
fi

### Tagging policy
# Always tag the build with the exact release (e.g. ...-release1.6.3).
# Additionally, tag the minor umbrella (e.g. ...-release1.6) if this
# TEMPLATE_VERSION is the newest patch in that minor series.
# Tag the generic version (e.g. emboldcreative/php:8.3-ubuntu24.04) only
# if this TEMPLATE_VERSION is the newest release overall for the
# VERSION_SUFFIX. To avoid making remote API calls (private registries,
# CI constraints), set SKIP_REGISTRY_CHECK=1 to skip remote checks and
# always add only the exact release tag and the generic tag.

RELEASE_MINOR_TAG="${REGISTRY_HOST}/${REGISTRY_USER}/${IMAGE_NAME}:${VERSION_SUFFIX}-release${TEMPLATE_VERSION%.*}"

should_tag_minor=false
should_tag_general=false

if [ "${SKIP_REGISTRY_CHECK:-0}" = "1" ]; then
	# Skip remote checks; default to tagging only the release and generic tag
	should_tag_minor=false
	should_tag_general=true
else
	# Query remote registry for tags. Support GHCR (ghcr.io) and Docker Hub.
	if [ "$REGISTRY_HOST" = "ghcr.io" ]; then
	  echo_highlight "Checking remote tags on GHCR to determine additional tags..."
	  ghcr_url="https://ghcr.io/v2/${REGISTRY_USER}/${IMAGE_NAME}/tags/list?n=100"
	  # Try authenticated request if token available
	  if [ -n "${GHCR_TOKEN:-}" ]; then
	    auth_header="-u ${GHCR_USER:-$REGISTRY_USER}:${GHCR_TOKEN}"
	  elif [ -f "${HOME}/.gh-pat.txt" ]; then
	    # curl -u can read password from stdin only via --user :token syntax; create a temporary auth file
	    tmpuser=${GHCR_USER:-$REGISTRY_USER}
	    tmpfile=$(mktemp)
	    cat "${HOME}/.gh-pat.txt" > "$tmpfile"
	    auth_header="-u ${tmpuser}:$(cat $tmpfile)"
	    rm -f "$tmpfile"
	  else
	    auth_header=""
	  fi
		if [ -n "$auth_header" ]; then
			remote_tags_json=$(eval curl -s $auth_header "${ghcr_url}") || remote_tags_json=""
		else
			remote_tags_json=$(curl -s "${ghcr_url}") || remote_tags_json=""
		fi
		if [ -n "$remote_tags_json" ]; then
			# require jq to parse GHCR JSON
			if command -v jq >/dev/null 2>&1; then
				remote_tags=$(printf "%s" "$remote_tags_json" | jq -r '.tags[]?')
			else
				echo_highlight "jq not found; cannot parse GHCR tags. Install jq or set SKIP_REGISTRY_CHECK=1 to skip remote checks."
				remote_tags=""
			fi
		else
			remote_tags=""
		fi
	else
	  echo_highlight "Checking remote tags on Docker Hub to determine additional tags..."
	  tags_json_url="https://hub.docker.com/v2/repositories/${REGISTRY_USER}/${IMAGE_NAME}/tags/?page_size=100"

	  # Use embedded Python to page the Docker Hub API and collect tag names.
		# Page Docker Hub API (requires jq). Collect tag names into remote_tags
		if command -v jq >/dev/null 2>&1; then
			url="$tags_json_url"
			remote_tags=""
			while [ -n "$url" ] && [ "$url" != "null" ]; do
				resp=$(curl -s "$url") || resp=""
				if [ -z "$resp" ]; then
					break
				fi
				# extract tag names
				page_tags=$(printf "%s" "$resp" | jq -r '.results[].name // empty')
				if [ -n "$page_tags" ]; then
					if [ -z "$remote_tags" ]; then
						remote_tags="$page_tags"
					else
						remote_tags="$remote_tags
	$page_tags"
					fi
				fi
				url=$(printf "%s" "$resp" | jq -r '.next // empty')
			done
		else
			echo_highlight "jq not found; cannot query Docker Hub API. Install jq or set SKIP_REGISTRY_CHECK=1 to skip remote checks."
			remote_tags=""
		fi
	fi

	if [ -z "$remote_tags" ]; then
		echo_highlight "Could not fetch remote tags — skipping remote-based tagging."
		should_tag_general=false
		should_tag_minor=false
	else
		# Determine latest overall release for this VERSION_SUFFIX
		# Match tags like: 8.3-ubuntu24.04-release1.6.3
		prefix="${VERSION_SUFFIX}-release"
		# Collect release versions for this VERSION_SUFFIX
		release_versions=()
		while read -r t; do
			case "$t" in
				${prefix}*)
					ver=${t#${prefix}}
					# normalize leading v if present
					ver=${ver#v}
					release_versions+=("$ver")
					;;
			esac
		done <<<"$remote_tags"

		# Determine latest overall release using version-aware sort (sort -V)
		if [ ${#release_versions[@]} -eq 0 ]; then
			latest_overall=""
		else
			latest_overall=$(printf "%s\n" "${release_versions[@]}" | sort -V | tail -n1)
		fi

		# Determine latest in this minor (e.g., 1.6)
		minor_prefix="${TEMPLATE_VERSION%.*}"
		filtered_versions=()
		for v in "${release_versions[@]}"; do
			case "$v" in
				${minor_prefix}.*|${minor_prefix})
					filtered_versions+=("$v")
					;;
			esac
		done
		if [ ${#filtered_versions[@]} -eq 0 ]; then
			latest_minor=""
		else
			latest_minor=$(printf "%s\n" "${filtered_versions[@]}" | sort -V | tail -n1)
		fi

		# Compare current TEMPLATE_VERSION
		if [ -n "$latest_minor" ] && [ "$TEMPLATE_VERSION" = "$latest_minor" ]; then
			should_tag_minor=true
		fi
		if [ -n "$latest_overall" ] && [ "$TEMPLATE_VERSION" = "$latest_overall" ]; then
			should_tag_general=true
		fi
	fi
fi

# Always add the exact release tag locally
docker tag "$RELEASE_TAG" "$RELEASE_TAG" || true

# Add minor tag if decided
if [ "$should_tag_minor" = true ]; then
	docker tag "$RELEASE_TAG" "$RELEASE_MINOR_TAG"
	echo "Also tagging minor umbrella: $RELEASE_MINOR_TAG"
fi

# Add general tag if decided
if [ "$should_tag_general" = true ]; then
	docker tag "$RELEASE_TAG" "$GENERAL_TAG"
	echo "Also tagging general version: $GENERAL_TAG"
fi

echo "Image built with tags:"
echo "  $RELEASE_TAG"
$([ "$should_tag_minor" = true ] && echo "  $RELEASE_MINOR_TAG")
$([ "$should_tag_general" = true ] && echo "  $GENERAL_TAG")
echo
echo "To push tags, run:" 
echo_highlight "  docker push $RELEASE_TAG"
if [ "$should_tag_minor" = true ]; then
	echo_highlight "  docker push $RELEASE_MINOR_TAG"
fi
if [ "$should_tag_general" = true ]; then
	echo_highlight "  docker push $GENERAL_TAG"
fi

# Offer to push; attempt GHCR login automatically if GHCR is used and token available
docker_login_for_push() {
	if [ "$REGISTRY_HOST" = "ghcr.io" ]; then
		if [ -n "${GHCR_TOKEN:-}" ]; then
			echo "Logging in to GHCR as ${GHCR_USER:-$REGISTRY_USER}..."
			echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER:-$REGISTRY_USER}" --password-stdin || echo_highlight "GHCR login failed"
		elif [ -f "${HOME}/.gh-pat.txt" ]; then
			echo "Using ${HOME}/.gh-pat.txt to login to GHCR as ${GHCR_USER:-$REGISTRY_USER}..."
			cat "${HOME}/.gh-pat.txt" | docker login ghcr.io -u "${GHCR_USER:-$REGISTRY_USER}" --password-stdin || echo_highlight "GHCR login failed"
		else
			echo_highlight "No GHCR token found in GHCR_TOKEN or ~/.gh-pat.txt — pushing will likely fail unless you are already logged in."
		fi
	fi
}

read -rp "Do you want to push the tags decided above now? [y/N]: " push_answer
if [[ "$push_answer" =~ ^[Yy]$ ]]; then
	docker_login_for_push
	echo "Pushing tags..."
	docker push "$RELEASE_TAG"
	if [ "$should_tag_minor" = true ]; then
		docker push "$RELEASE_MINOR_TAG"
	fi
	if [ "$should_tag_general" = true ]; then
		docker push "$GENERAL_TAG"
	fi
	echo "Push complete."
fi
