#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.scripts/update-lib.sh"

export ADDON_DIR="gitea"
export DISPLAY_NAME="Gitea"
export VERSION_ARG=""
export USE_BUILD_YAML="true"
export UPSTREAM_REPO="go-gitea/gitea"
export VERSION_TYPE="calver"
export TAG_PREFIX="v"
export FILES_TO_UPDATE="config.yaml build.yaml"
export PKG_PATH=""
CURRENT_MINOR=$(grep -Eo "gitea/gitea:[0-9]+\.[0-9]+" "$ADDON_DIR"/build.yaml | head -1 | sed "s/.*://" || echo "")
echo "current_minor=$CURRENT_MINOR" >> $GITHUB_OUTPUT
CONFIG_VERSION=$(get_config_version "$ADDON_DIR")
echo "config_version=$CONFIG_VERSION" >> $GITHUB_OUTPUT
IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_release "$UPSTREAM_REPO" "$VERSION_TYPE" "$TAG_PREFIX")"
echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT
echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT
echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT
LATEST_MINOR=$(echo "$LATEST_VERSION" | cut -d. -f1,2)
echo "latest_minor=$LATEST_MINOR" >> $GITHUB_OUTPUT
COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_MINOR" "$RELEASE_TYPE" "$VERSION_TYPE" "$CURRENT_MINOR")
echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done
NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)
[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0
NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)
EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)
EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)
IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)
NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")
echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT
if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_MINOR"; fi
echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT
sed -i "s/^version: .*/version: \"$NEW_ADDON_VERSION\"/" "$ADDON_DIR"/config.yaml
ESCAPED_CURRENT=$(printf '%s' "$CURRENT_MINOR" | sed 's/\./\\./g')
sed -i "s|gitea/gitea:${ESCAPED_CURRENT}-nightly|gitea/gitea:${LATEST_MINOR}-nightly|g" "$ADDON_DIR"/build.yaml
git add "$ADDON_DIR/config.yaml" "$ADDON_DIR/build.yaml"
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi
