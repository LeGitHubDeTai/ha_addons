#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/.scripts/update-lib.sh"

export ADDON_DIR="nzbget"
export DISPLAY_NAME="Nzbget"
export VERSION_ARG="NZBGET_VERSION"
export USE_BUILD_YAML="true"
export UPSTREAM_REPO="linuxserver/docker-nzbget"
export VERSION_TYPE="ls"
export TAG_PREFIX="nzbget"
export FILES_TO_UPDATE="config.yaml build.yaml"
BUILD_TAG=$(get_build_yaml_tag "$ADDON_DIR")
BUILD_VERSION=$(echo "$BUILD_TAG" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" || echo "")
echo "build_tag=$BUILD_TAG" >> $GITHUB_OUTPUT
echo "build_version=$BUILD_VERSION" >> $GITHUB_OUTPUT
CONFIG_VERSION=$(get_config_version "$ADDON_DIR")
echo "config_version=$CONFIG_VERSION" >> $GITHUB_OUTPUT

IFS="|" read -r LATEST_TAG LATEST_VERSION LATEST_BUILD RELEASE_TYPE RELEASE_URL MINOR_VERSION <<< "$(get_latest_ls_release "$ADDON_DIR" "$TAG_PREFIX")"
echo "latest_tag=$LATEST_TAG" >> $GITHUB_OUTPUT
echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT
echo "latest_build=$LATEST_BUILD" >> $GITHUB_OUTPUT
echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT
echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT
[ -n "$MINOR_VERSION" ] && echo "minor_version=$MINOR_VERSION" >> $GITHUB_OUTPUT

COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$BUILD_VERSION")
echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done
NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)
[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0
NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)
EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)
EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)
IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)

NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")
echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT

if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_VERSION"; fi
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi
echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT

sed -i "s/^version: .*/version: \"$NEW_ADDON_VERSION\"/" "$ADDON_DIR"/config.yaml
sed -i "s/${TAG_PREFIX}[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*-ls[0-9]*/${TAG_PREFIX}${LATEST_VERSION}-${LATEST_BUILD}/g" "$ADDON_DIR"/build.yaml

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
for f in $FILES_TO_UPDATE; do git add "$ADDON_DIR/$f"; done
FORCE_FLAG="${{ github.event.inputs.force || 'true' }}"
if git diff --cached --quiet; then
  if [ "$FORCE_FLAG" = "true" ]; then git commit --allow-empty -m "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"; else echo "No changes"; exit 0; fi
else
  git commit -m "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"
fi

git fetch origin || true
if [ "$FORCE_FLAG" = "true" ]; then git push origin "$BRANCH_NAME" --force; elif git rev-parse origin/"$BRANCH_NAME" >/dev/null 2>&1; then [ -n "$(git log origin/"$BRANCH_NAME"..HEAD 2>/dev/null)" ] && git push origin "$BRANCH_NAME" --force || echo "No new commits"; else git push origin "$BRANCH_NAME"; fi

create_or_update_pr "$BRANCH_NAME" "$DISPLAY_NAME" "$LATEST_VERSION" "$NEW_ADDON_VERSION" "$RELEASE_TYPE" "$RELEASE_URL" "$IS_NEW_VERSION"
