# -*- coding: utf-8 -*-
"""generate-update-steps
Generates .updates/<addon>.sh scripts and the unified auto-upgrades workflow."""
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPDATES_DIR = os.path.join(REPO, ".updates")
os.makedirs(UPDATES_DIR, exist_ok=True)

ADDONS = [
    ("Cloudflared", "cloudflared", "CLOUDFLARED_VERSION", "false", "cloudflare/cloudflared", "calver", "", "config.yaml Dockerfile", ""),
    ("Deemix", "deemix", "DEEMIX_VERSION", "false", "bambanah/deemix", "deemix", "", "config.yaml Dockerfile", ""),
    ("FossFLOW", "FossFLOW", "FOSSFLOW_VERSION", "false", "Abrar74774/FossFLOW", "calver", "", "config.yaml Dockerfile", ""),
    ("Gitea", "gitea", "GITEA_VERSION", "true", "go-gitea/gitea", "ls", "", "config.yaml build.yaml", "gitea"),
    ("Mindwtr", "mindwtr", "MINDWTR_VERSION", "false", "dongdongbh/Mindwtr", "calver", "", "config.yaml Dockerfile", ""),
    ("Obsidian", "obsidian", "OBSIDIAN_VERSION", "false", "obsidianhq/obsidian", "calver", "", "config.yaml Dockerfile", ""),
    ("Planka", "planka", "PLANKA_VERSION", "false", "plankanban/planka", "calver", "", "config.yaml Dockerfile", ""),
    ("Portainer", "portainer", "PORTAINER_VERSION", "false", "portainer/portainer", "direct", "", "config.yaml build.yaml", ""),
    ("Requestly", "requestly", "REQUESTLY_VERSION", "false", "requestly/requestly", "calver", "", "config.yaml Dockerfile", ""),
    ("Soulseek", "soulseek", "SLSKD_VERSION", "false", "slskd/slskd", "calver", "", "config.yaml Dockerfile", ""),
    ("Storybook", "storybook", "STORYBOOK_VERSION", "false", "storybookjs/storybook", "calver", "", "config.yaml Dockerfile", ""),
    ("Syncthing", "syncthing", "SYNCTHING_VERSION", "false", "syncthing/syncthing", "calver", "", "config.yaml Dockerfile", ""),
    ("Timescaledb", "timescaledb", "TIMESCALEDB_VERSION", "false", "timescale/timescaledb", "calver", "", "config.yaml Dockerfile", ""),
    ("Webdav", "webdav", "WEBDAV_VERSION", "false", "hacdias/webdav", "calver", "", "config.yaml Dockerfile", ""),
    ("YouTube-dl", "youtube-dl", "YOUTUBE_DL_VERSION", "false", "yt-dlp/yt-dlp", "calver", "", "config.yaml Dockerfile", ""),
    ("YouTube-dlp", "youtube-dlp", "YOUTUBE_DLP_VERSION", "false", "yt-dlp/yt-dlp", "calver", "", "config.yaml Dockerfile", ""),
    ("Isoman", "isoman", "ISOMAN_VERSION", "false", "home-assistant/addons-data-isoman", "calver", "", "config.yaml Dockerfile", ""),
    ("Nzbget", "nzbget", "NZBGET_VERSION", "true", "linuxserver/docker-nzbget", "ls", "nzbget", "config.yaml build.yaml", "nzbget"),
    ("Mopidy", "mopidy", "MOPIDY_VERSION", "false", "mopidy/mopidy", "calver", "", "config.yaml Dockerfile", ""),
    ("Drawio", "drawio", "DRAWIO_VERSION", "false", "jgraph/drawio", "calver", "", "config.yaml Dockerfile", ""),
    ("Fizzy", "fizzy", "FIZZY_VERSION", "false", "fizzy-org/fizzy", "calver", "", "config.yaml Dockerfile", ""),
    ("Lidarr", "lidarr", "", "true", "linuxserver/docker-lidarr", "ls", "lidarr", "config.yaml build.yaml", "lidarr"),
    ("Lidarr-develop", "lidarr_develop", "", "true", "linuxserver/docker-lidarr", "ls", "lidarr-develop", "config.yaml build.yaml", "lidarr"),
    ("Lidarr-nightly", "lidarr_nightly", "", "true", "linuxserver/docker-lidarr", "ls", "lidarr-nightly", "config.yaml build.yaml", "lidarr"),
    ("Docmost", "docmost", "DOCMOST_VERSION", "false", "docmost/docmost", "calver", "", "config.yaml Dockerfile", ""),
    ("Dolibarr", "dolibarr", "DOLIBARR_VERSION", "false", "Dolibarr/Dolibarr", "calver", "", "config.yaml Dockerfile", ""),
    ("Drawnix", "drawnix", "DRAWNIX_VERSION", "false", "drawnix/drawnix", "calver", "", "config.yaml Dockerfile", ""),
    ("Scanopy", "scanopy", "SCANOPY_VERSION", "false", "scanopy/scanopy", "calver", "", "config.yaml Dockerfile", ""),
]

for name, d, ver_arg, use_by, up_repo, ver_type, tag_prefix, files_upd, ls_dir in ADDONS:
    lines = [
        "#!/bin/bash",
        "set -euo pipefail",
        'SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"',
        'source "$SCRIPT_DIR/.scripts/update-lib.sh"',
        "",
        f'export ADDON_DIR="{d}"',
        f'export DISPLAY_NAME="{name}"',
        f'export VERSION_ARG="{ver_arg}"',
        f'export USE_BUILD_YAML="{use_by}"',
        f'export UPSTREAM_REPO="{up_repo}"',
        f'export VERSION_TYPE="{ver_type}"',
        f'export TAG_PREFIX="{tag_prefix}"',
        f'export FILES_TO_UPDATE="{files_upd}"',
    ]

    if use_by == "true":
        lines += [
            'BUILD_TAG=$(get_build_yaml_tag "$ADDON_DIR")',
            'BUILD_VERSION=$(echo "$BUILD_TAG" | grep -oE "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || echo "")',
            'echo "build_tag=$BUILD_TAG" >> $GITHUB_OUTPUT',
            'echo "build_version=$BUILD_VERSION" >> $GITHUB_OUTPUT',
        ]
    elif ver_type == "direct":
        lines += [
            f'BUILD_VERSION=$(grep -Eo "{d}[^:]*:[0-9]+\\.[0-9]+\\.[0-9]+" "$ADDON_DIR"/build.yaml | head -1 | sed "s/.*://")',
            'echo "build_version=$BUILD_VERSION" >> $GITHUB_OUTPUT',
        ]
    else:
        lines += [
            'DOCKERFILE_VERSION=$(get_dockerfile_version "$ADDON_DIR" "$VERSION_ARG")',
            'echo "dockerfile_version=$DOCKERFILE_VERSION" >> $GITHUB_OUTPUT',
        ]

    lines += [
        'CONFIG_VERSION=$(get_config_version "$ADDON_DIR")',
        'echo "config_version=$CONFIG_VERSION" >> $GITHUB_OUTPUT',
        "",
    ]

    if ver_type == "ls":
        lines += [
            'IFS="|" read -r LATEST_TAG LATEST_VERSION LATEST_BUILD RELEASE_TYPE RELEASE_URL MINOR_VERSION <<< "$(get_latest_ls_release "$ADDON_DIR" "$TAG_PREFIX")"',
            'echo "latest_tag=$LATEST_TAG" >> $GITHUB_OUTPUT',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "latest_build=$LATEST_BUILD" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
            '[ -n "$MINOR_VERSION" ] && echo "minor_version=$MINOR_VERSION" >> $GITHUB_OUTPUT',
        ]
    else:
        lines += [
            'IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_release "$UPSTREAM_REPO" "$VERSION_TYPE")"',
            'echo "latest_release=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
        ]

    lines += [
        "",
        'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$BUILD_VERSION")',
        'echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done',
        'NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)',
        '[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0',
        'NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)',
        'EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)',
        'EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)',
        'IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)',
        "",
        'NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")',
        'echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT',
        "",
        'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_VERSION"; fi',
        'if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi',
        'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
        "",
    ]

    if use_by == "true":
        if d == "gitea":
            lines += [
                'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
                'sed -i "s/gitea\\/gitea:[0-9]*\\\\.[0-9]*-nightly/gitea\\/gitea:$MINOR_VERSION-nightly/g" "$ADDON_DIR"/build.yaml',
            ]
        else:
            lines += [
                'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
                'sed -i "s/${TAG_PREFIX}[0-9]*\\.[0-9]*\\.[0-9]*\\.[0-9]*-ls[0-9]*/${TAG_PREFIX}${LATEST_VERSION}-${LATEST_BUILD}/g" "$ADDON_DIR"/build.yaml',
            ]
    elif ver_type == "direct":
        lines += [
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            f'sed -i "s|{d}/{d}-ce:[0-9][0-9.]*|{d}/{d}-ce:${{LATEST_VERSION}}|g" "$ADDON_DIR"/build.yaml',
        ]
    else:
        lines += [
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            'sed -i "s/ARG $VERSION_ARG=.*/ARG $VERSION_ARG=\\"$LATEST_VERSION\\"/" "$ADDON_DIR"/Dockerfile',
        ]

    lines += [
        "",
        'git config --local user.email "action@github.com"',
        'git config --local user.name "GitHub Action"',
        'for f in $FILES_TO_UPDATE; do git add "$ADDON_DIR/$f"; done',
        "FORCE_FLAG=\"${{ github.event.inputs.force || 'true' }}\"",
        'if git diff --cached --quiet; then',
        '  if [ "$FORCE_FLAG" = "true" ]; then git commit --allow-empty -m "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"; else echo "No changes"; exit 0; fi',
        'else',
        '  git commit -m "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"',
        'fi',
        "",
        'git fetch origin || true',
        'if [ "$FORCE_FLAG" = "true" ]; then git push origin "$BRANCH_NAME" --force; elif git rev-parse origin/"$BRANCH_NAME" >/dev/null 2>&1; then [ -n "$(git log origin/"$BRANCH_NAME"..HEAD 2>/dev/null)" ] && git push origin "$BRANCH_NAME" --force || echo "No new commits"; else git push origin "$BRANCH_NAME"; fi',
        "",
        'create_or_update_pr "$BRANCH_NAME" "$DISPLAY_NAME" "$LATEST_VERSION" "$NEW_ADDON_VERSION" "$RELEASE_TYPE" "$RELEASE_URL" "$IS_NEW_VERSION"',
    ]

    content = "\n".join(lines) + "\n"
    path = os.path.join(UPDATES_DIR, d + ".sh")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    os.chmod(path, 0o755)

print(f"Generated {len(ADDONS)} addon scripts in {UPDATES_DIR}")

# Also generate the workflow YAML
WORKFLOW_PATH = os.path.join(REPO, ".github", "workflows", "auto-upgrades.yml")
os.makedirs(os.path.dirname(WORKFLOW_PATH), exist_ok=True)

workflow_content = """name: Auto-upgrades

on:
  schedule:
    - cron: '0 9 * * *'
  workflow_dispatch:
    inputs:
      force:
        description: 'Force recreate PR even if one already exists (closed/merged)'
        required: false
        default: true
        type: boolean

env:
  GH_TOKEN: ${{ github.token }}

jobs:
  discover-addons:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.matrix.outputs.matrix }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Discover addon scripts
        id: matrix
        run: |
          SCRIPTS=$(find .updates -maxdepth 1 -name '*.sh' -type f | sort)
          MATRIX="["
          FIRST=true
          for script in $SCRIPTS; do
            ADDON_DIR=$(basename "$script" .sh)
            DISPLAY_NAME=$(grep 'export DISPLAY_NAME=' "$script" | sed 's/.*export DISPLAY_NAME=//' | sed 's/"//g')
            VERSION_ARG=$(grep 'export VERSION_ARG=' "$script" | sed 's/.*export VERSION_ARG=//' | sed 's/"//g')
            USE_BUILD_YAML=$(grep 'export USE_BUILD_YAML=' "$script" | sed 's/.*export USE_BUILD_YAML=//' | sed 's/"//g')
            UPSTREAM_REPO=$(grep 'export UPSTREAM_REPO=' "$script" | sed 's/.*export UPSTREAM_REPO=//' | sed 's/"//g')
            VERSION_TYPE=$(grep 'export VERSION_TYPE=' "$script" | sed 's/.*export VERSION_TYPE=//' | sed 's/"//g')
            TAG_PREFIX=$(grep 'export TAG_PREFIX=' "$script" | sed 's/.*export TAG_PREFIX=//' | sed 's/"//g')
            FILES_TO_UPDATE=$(grep 'export FILES_TO_UPDATE=' "$script" | sed 's/.*export FILES_TO_UPDATE=//' | sed 's/"//g')

            if [ "$FIRST" = "true" ]; then
              FIRST=false
            else
              MATRIX="$MATRIX,"
            fi
            MATRIX="${MATRIX}{\"addon_dir\":\"$ADDON_DIR\",\"display_name\":\"$DISPLAY_NAME\",\"version_arg\":\"$VERSION_ARG\",\"use_build_yaml\":\"$USE_BUILD_YAML\",\"upstream_repo\":\"$UPSTREAM_REPO\",\"version_type\":\"$VERSION_TYPE\",\"tag_prefix\":\"$TAG_PREFIX\",\"files_to_update\":\"$FILES_TO_UPDATE\"}"
          done
          MATRIX="$MATRIX]"
          echo "matrix=$MATRIX" >> $GITHUB_OUTPUT
          echo "Discovered $(ls .updates/*.sh | wc -l) addon scripts"

  auto-upgrade:
    needs: discover-addons
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.discover-addons.outputs.matrix) }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Run auto-upgrade for ${{ matrix.display_name }}
        id: upgrade
        env:
          ADDON_DIR: ${{ matrix.addon_dir }}
          DISPLAY_NAME: ${{ matrix.display_name }}
          VERSION_ARG: ${{ matrix.version_arg }}
          USE_BUILD_YAML: ${{ matrix.use_build_yaml }}
          UPSTREAM_REPO: ${{ matrix.upstream_repo }}
          VERSION_TYPE: ${{ matrix.version_type }}
          TAG_PREFIX: ${{ matrix.tag_prefix }}
          FILES_TO_UPDATE: ${{ matrix.files_to_update }}
          FORCE_FLAG: ${{ github.event.inputs.force || 'true' }}
        run: |
          bash .updates/${{ matrix.addon_dir }}.sh
"""

with open(WORKFLOW_PATH, "w", encoding="utf-8") as f:
    f.write(workflow_content)

print(f"Generated workflow at {WORKFLOW_PATH}")
print("Done!")
