#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.scripts/update-lib.sh"

export ADDON_DIR="penpot"
export DISPLAY_NAME="Penpot"
export VERSION_ARG="PENPOT_VERSION"
export USE_BUILD_YAML="false"
export UPSTREAM_REPO="penpot/penpot"
export VERSION_TYPE="calver"
export TAG_PREFIX=""
export FILES_TO_UPDATE="config.yaml Dockerfile"
export PKG_PATH=""
CURRENT_MINOR=$(grep -m1 -E "^ARG PENPOT_VERSION=" "$ADDON_DIR"/Dockerfile | sed "s/.*=//" | sed 's/"//g' | sed "s/[[:space:]]*//g" | sed "s/\\r//g" | cut -d. -f1,2 || echo "")
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
sed -i "s/ARG PENPOT_VERSION=.*/ARG PENPOT_VERSION=\"${LATEST_MINOR}\"/" "$ADDON_DIR"/Dockerfile
git add "$ADDON_DIR/config.yaml" "$ADDON_DIR/Dockerfile"
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi
