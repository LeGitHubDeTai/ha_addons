# -*- coding: utf-8 -*-
"""generate-update-steps
Generates .updates/<addon>.sh scripts and the unified auto-upgrades workflow.

Addons scripts only handle version detection and file updates.
Commit/push/PR is handled by the workflow.
"""
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

    # Version detection
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
    ]

    # Latest release
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

    # Check PR status and compare
    BUILD_VERSION_VAR = 'BUILD_VERSION' if use_by == 'true' else 'DOCKERFILE_VERSION'
    lines += [
        f'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$BUILD_VERSION_VAR")'.replace('BUILD_VERSION_VAR', BUILD_VERSION_VAR),
        'echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done',
        'NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)',
        '[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0',
        'NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)',
        'EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)',
        'EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)',
        'IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)',
    ]

    # Generate new addon version
    lines += [
        'NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")',
        'echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT',
    ]

    # Determine branch name
    lines += [
        'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_VERSION"; fi',
        'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
    ]

    # Update files (no commit/push/PR here)
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

    # Stage files
    lines += [
        'git add',
    ]
    for f in files_upd.split():
        lines[-1] += f' "$ADDON_DIR/{f}"'

    # Create branch
    lines += [
        'if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi',
    ]

    content = "\n".join(lines) + "\n"
    path = os.path.join(UPDATES_DIR, d + ".sh")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    os.chmod(path, 0o755)
    print(f"Generated: {path}")

print(f"\nGenerated {len(ADDONS)} addon scripts in {UPDATES_DIR}")

# Generate the workflow YAML
WORKFLOW_PATH = os.path.join(REPO, ".github", "workflows", "auto-upgrades.yml")
os.makedirs(os.path.dirname(WORKFLOW_PATH), exist_ok=True)

workflow_content = '''name: Auto-upgrades

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
          MATRIX=$(find .updates -maxdepth 1 -name '*.sh' -type f | sort | while read -r script; do
            ADDON_DIR=$(basename "$script" .sh)
            DISPLAY_NAME=$(grep 'export DISPLAY_NAME=' "$script" | sed 's/.*export DISPLAY_NAME=//' | sed 's/"//g')
            VERSION_ARG=$(grep 'export VERSION_ARG=' "$script" | sed 's/.*export VERSION_ARG=//' | sed 's/"//g')
            USE_BUILD_YAML=$(grep 'export USE_BUILD_YAML=' "$script" | sed 's/.*export USE_BUILD_YAML=//' | sed 's/"//g')
            UPSTREAM_REPO=$(grep 'export UPSTREAM_REPO=' "$script" | sed 's/.*export UPSTREAM_REPO=//' | sed 's/"//g')
            VERSION_TYPE=$(grep 'export VERSION_TYPE=' "$script" | sed 's/.*export VERSION_TYPE=//' | sed 's/"//g')
            TAG_PREFIX=$(grep 'export TAG_PREFIX=' "$script" | sed 's/.*export TAG_PREFIX=//' | sed 's/"//g')
            FILES_TO_UPDATE=$(grep 'export FILES_TO_UPDATE=' "$script" | sed 's/.*export FILES_TO_UPDATE=//' | sed 's/"//g')
            jq -n --arg addon_dir "$ADDON_DIR" \
                  --arg display_name "$DISPLAY_NAME" \
                  --arg version_arg "$VERSION_ARG" \
                  --arg use_build_yaml "$USE_BUILD_YAML" \
                  --arg upstream_repo "$UPSTREAM_REPO" \
                  --arg version_type "$VERSION_TYPE" \
                  --arg tag_prefix "$TAG_PREFIX" \
                  --arg files_to_update "$FILES_TO_UPDATE" \
                  '{addon_dir:$addon_dir, display_name:$display_name, version_arg:$version_arg, use_build_yaml:$use_build_yaml, upstream_repo:$upstream_repo, version_type:$version_type, tag_prefix:$tag_prefix, files_to_update:$files_to_update}'
          done | jq -s '.')
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

      - name: Commit and push changes
        if: steps.upgrade.outputs.needs_upgrade == 'true'
        env:
          BRANCH_NAME: ${{ steps.upgrade.outputs.branch_name }}
          DISPLAY_NAME: ${{ matrix.display_name }}
          NEW_ADDON_VERSION: ${{ steps.upgrade.outputs.new_addon_version }}
          LATEST_VERSION: ${{ steps.upgrade.outputs.latest_version }}
          FORCE_FLAG: ${{ github.event.inputs.force || 'true' }}
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git commit -m "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"

          git fetch origin || true
          if [ "$FORCE_FLAG" = "true" ]; then
            git push origin "$BRANCH_NAME" --force
          elif git rev-parse origin/"$BRANCH_NAME" >/dev/null 2>&1; then
            if [ -n "$(git log origin/"$BRANCH_NAME"..HEAD 2>/dev/null)" ]; then
              git push origin "$BRANCH_NAME" --force
            else
              echo "No new commits to push"
            fi
          else
            git push origin "$BRANCH_NAME"
          fi

      - name: Create or Update Pull Request
        if: steps.upgrade.outputs.needs_upgrade == 'true'
        env:
          BRANCH_NAME: ${{ steps.upgrade.outputs.branch_name }}
          DISPLAY_NAME: ${{ matrix.display_name }}
          LATEST_VERSION: ${{ steps.upgrade.outputs.latest_version }}
          NEW_ADDON_VERSION: ${{ steps.upgrade.outputs.new_addon_version }}
          RELEASE_TYPE: ${{ steps.upgrade.outputs.release_type }}
          RELEASE_URL: ${{ steps.upgrade.outputs.release_url }}
          IS_NEW_VERSION: ${{ steps.upgrade.outputs.is_new_version }}
          FORCE_FLAG: ${{ github.event.inputs.force || 'true' }}
        run: |
          OPEN_PR=$(gh pr list --head "$BRANCH_NAME" --base main --state open --json number --jq '.[0].number' 2>/dev/null || echo "")
          ANY_PR=$(gh pr list --head "$BRANCH_NAME" --base main --state all --json number --jq '.[0].number' 2>/dev/null || echo "")

          if [ -n "$OPEN_PR" ]; then
            echo "Open PR #$OPEN_PR found, updating labels..."
            CURRENT_LABELS=$(gh pr view "$OPEN_PR" --json labels --jq '.labels[].name' 2>/dev/null || echo "")
            if echo "$CURRENT_LABELS" | grep -q "pre-release\\|latest"; then
              gh pr edit "$OPEN_PR" --remove-label "pre-release,latest" 2>/dev/null || true
            fi
            gh pr edit "$OPEN_PR" --add-label "$RELEASE_TYPE"
            if [ "$IS_NEW_VERSION" = "true" ]; then
              CURRENT_TITLE=$(gh pr view "$OPEN_PR" --json title --jq '.title' 2>/dev/null || echo "")
              NEW_TITLE="Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)"
              if [ "$CURRENT_TITLE" != "$NEW_TITLE" ]; then
                gh pr edit "$OPEN_PR" --title "$NEW_TITLE"
              fi
            fi
            echo "PR #$OPEN_PR updated successfully"
          elif [ "$FORCE_FLAG" = "true" ]; then
            gh pr create \
              --base main \
              --head "$BRANCH_NAME" \
              --title "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)" \
              --body "Auto-upgrade $DISPLAY_NAME to version $LATEST_VERSION

**Changes:**
- Updated config.yaml addon version to $NEW_ADDON_VERSION
- Updated upstream version to $LATEST_VERSION

**Release:** $RELEASE_URL

This PR was created automatically by the auto-upgrade workflow (forced recreation)." \
              --label "auto-upgrade,dependencies,$RELEASE_TYPE"
            echo "PR created successfully (forced)"
          elif [ -n "$ANY_PR" ]; then
            echo "PR #$ANY_PR already exists but is closed/merged - not creating duplicate"
          elif [ "$IS_NEW_VERSION" = "true" ]; then
            gh pr create \
              --base main \
              --head "$BRANCH_NAME" \
              --title "Upgrade $DISPLAY_NAME to $LATEST_VERSION (addon $NEW_ADDON_VERSION)" \
              --body "Auto-upgrade $DISPLAY_NAME to version $LATEST_VERSION

**Changes:**
- Updated config.yaml addon version to $NEW_ADDON_VERSION
- Updated upstream version to $LATEST_VERSION

**Release:** $RELEASE_URL

This PR was created automatically by the auto-upgrade workflow." \
              --label "auto-upgrade,dependencies,$RELEASE_TYPE"
            echo "PR created successfully"
          else
            echo "No new version and no open PR - nothing to do"
          fi
'''

with open(WORKFLOW_PATH, "w", encoding="utf-8") as f:
    f.write(workflow_content)

print(f"Generated workflow at {WORKFLOW_PATH}")
print("Done!")
