#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.scripts/update-lib.sh"

export ADDON_DIR="ctfreak"
export DISPLAY_NAME="Ctfreak"
export VERSION_ARG=""
export USE_BUILD_YAML="true"
export UPSTREAM_REPO="jypsoftware/ctfreak"
export VERSION_TYPE="calver"
export TAG_PREFIX=""
export FILES_TO_UPDATE="config.yaml build.yaml"
export PKG_PATH=""

# CTFREAK is proprietary software: no GitHub releases. The version is the
# Docker Hub image tag in build.yaml (jypsoftware/ctfreak:X.Y.Z).
get_latest_dockerhub_tag() {
    local repo="$1"
    local data
    data=$(curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags?page_size=100")
    local latest
    latest=$(echo "$data" | jq -r '.results[].name' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
    if [ -z "$latest" ]; then
        echo "ERROR: no valid semver tag found on Docker Hub for ${repo}" >&2
        return 1
    fi
    echo "$latest|latest|https://hub.docker.com/r/${repo}/tags"
}

BUILD_TAG=$(grep -E 'jypsoftware/ctfreak:' "$ADDON_DIR"/build.yaml | head -1 | sed 's/.*ctfreak://' | sed 's/[[:space:]]*//' | sed 's/"//g' | sed 's/\r//g' || true)
CURRENT_TAG="$BUILD_TAG"
echo "build_tag=$BUILD_TAG" >> "$GITHUB_OUTPUT"
echo "current_tag=$CURRENT_TAG" >> "$GITHUB_OUTPUT"
CONFIG_VERSION=$(get_config_version "$ADDON_DIR")
echo "config_version=$CONFIG_VERSION" >> "$GITHUB_OUTPUT"
IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_dockerhub_tag "$UPSTREAM_REPO")"
echo "latest_version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
echo "release_type=$RELEASE_TYPE" >> "$GITHUB_OUTPUT"
echo "release_url=$RELEASE_URL" >> "$GITHUB_OUTPUT"
COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$CURRENT_TAG")
echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> "$GITHUB_OUTPUT"; done
NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)
[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0
NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)
EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)
EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)
IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)
NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")
echo "new_addon_version=$NEW_ADDON_VERSION" >> "$GITHUB_OUTPUT"
if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-$LATEST_VERSION"; fi
echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"
sed -i "s/^version: .*/version: \"$NEW_ADDON_VERSION\"/" "$ADDON_DIR"/config.yaml
ESCAPED_CURRENT=$(printf '%s' "$CURRENT_TAG" | sed 's/\./\\./g')
sed -i "s/${ESCAPED_CURRENT}/${LATEST_VERSION}/g" "$ADDON_DIR"/build.yaml
git add "$ADDON_DIR/config.yaml" "$ADDON_DIR/build.yaml"
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi
