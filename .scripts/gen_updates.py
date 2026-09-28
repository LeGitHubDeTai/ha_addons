# -*- coding: utf-8 -*-
"""generate-update-steps
Generates .updates/<addon>.sh scripts.

Addons scripts only handle version detection and file updates.
Commit/push/PR is handled by the workflow (.github/workflows/auto-upgrades.yml),
which discovers scripts dynamically -- it does NOT need regeneration.

Run: python3 .scripts/gen_updates.py
Any hand-edit to .updates/*.sh will be OVERWRITTEN.
Put all per-addon knowledge in the ADDONS table below.
"""
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPDATES_DIR = os.path.join(REPO, ".updates")
os.makedirs(UPDATES_DIR, exist_ok=True)

# (DisplayName, addon_dir, VERSION_ARG, USE_BUILD_YAML, UPSTREAM_REPO,
#  VERSION_TYPE, TAG_PREFIX, FILES_TO_UPDATE, LS_REPO, PKG_PATH)
# VERSION_TYPE: calver | direct (portainer) | deemix | ls (linuxserver) |
#               fizzy (fizzy@<sha> tags) | node (version from package.json)
# TAG_PREFIX: stripped from upstream tags before compare (e.g. "v").
# LS_REPO: linuxserver repo short name (default: docker-<addon_dir>).
# PKG_PATH: package.json path for VERSION_TYPE=node (env PKG_PATH in lib).
ADDONS = [
    ("Cloudflared", "cloudflared", "CLOUDFLARED_VERSION", "false", "cloudflare/cloudflared", "calver", "", "config.yaml Dockerfile", "", ""),
    ("Deemix", "deemix", "DEEMIX_VERSION", "false", "bambanah/deemix", "deemix", "", "config.yaml Dockerfile", "", ""),
    ("FossFLOW", "FossFLOW", "FOSSFLOW_VERSION", "false", "Abrar74774/FossFLOW", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Gitea", "gitea", "", "true", "go-gitea/gitea", "calver", "v", "config.yaml build.yaml", "", ""),
    ("Mindwtr", "mindwtr", "MINDWTR_VERSION", "false", "dongdongbh/Mindwtr", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Obsidian", "obsidian", "", "true", "linuxserver/docker-obsidian", "ls", "v", "config.yaml build.yaml", "docker-obsidian", ""),
    ("Planka", "planka", "PLANKA_VERSION", "false", "plankanban/planka", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Portainer", "portainer", "PORTAINER_VERSION", "false", "portainer/portainer", "direct", "", "config.yaml build.yaml", "", ""),
    ("Requestly", "requestly", "REQUESTLY_APP_VERSION", "false", "requestly/interceptor", "node", "", "config.yaml Dockerfile", "", "app/package.json"),
    ("Soulseek", "soulseek", "SLSKD_VERSION", "false", "slskd/slskd", "calver", "", "config.yaml Dockerfile", "", ""),
    ("Storybook", "storybook", "STORYBOOK_VERSION", "false", "storybookjs/storybook", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Syncthing", "syncthing", "SYNCTHING_VERSION", "false", "syncthing/syncthing", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Timescaledb", "timescaledb", "TIMESCALEDB_VERSION", "false", "timescale/timescaledb", "calver", "", "config.yaml Dockerfile", "", ""),
    ("Webdav", "webdav", "WEBDAV_VERSION", "false", "hacdias/webdav", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("YouTube-dl", "youtube-dl", "YOUTUBE_DL_VERSION", "false", "yt-dlp/yt-dlp", "calver", "", "config.yaml Dockerfile", "", ""),
    ("YouTube-dlp", "youtube-dlp", "YOUTUBE_DLP_VERSION", "false", "yt-dlp/yt-dlp", "calver", "", "config.yaml Dockerfile", "", ""),
    ("Isoman", "isoman", "ISOMAN_VERSION", "false", "aloks98/isoman", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Nzbget", "nzbget", "", "true", "linuxserver/docker-nzbget", "ls", "v", "config.yaml build.yaml", "docker-nzbget", ""),
    ("Mopidy", "mopidy", "MOPIDY_VERSION", "false", "mopidy/mopidy", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Drawio", "drawio", "DRAWIO_VERSION", "false", "jgraph/drawio", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Fizzy", "fizzy", "FIZZY_VERSION", "false", "basecamp/fizzy", "fizzy", "", "config.yaml Dockerfile", "", ""),
    ("Lidarr", "lidarr", "", "true", "linuxserver/docker-lidarr", "ls", "", "config.yaml build.yaml", "docker-lidarr", ""),
    ("Lidarr-develop", "lidarr_develop", "", "true", "linuxserver/docker-lidarr", "ls", "develop-", "config.yaml build.yaml", "docker-lidarr", ""),
    ("Lidarr-nightly", "lidarr_nightly", "", "true", "linuxserver/docker-lidarr", "ls", "nightly-", "config.yaml build.yaml", "docker-lidarr", ""),
    ("Docmost", "docmost", "DOCMOST_VERSION", "false", "docmost/docmost", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Dolibarr", "dolibarr", "DOLIBARR_VERSION", "false", "Dolibarr/Dolibarr", "calver", "", "config.yaml Dockerfile", "", ""),
    ("Drawnix", "drawnix", "DRAWNIX_VERSION", "false", "plait-board/drawnix", "calver", "v", "config.yaml Dockerfile", "", ""),
    ("Scanopy", "scanopy", "SCANOPY_VERSION", "false", "scanopy/scanopy", "calver", "v", "config.yaml Dockerfile", "", ""),
]

TAIL_COMPARE = [
    'echo "$COMPARE_RESULT" | while IFS="=" read -r key value; do echo "$key=$value" >> $GITHUB_OUTPUT; done',
    'NEEDS_UPGRADE=$(echo "$COMPARE_RESULT" | grep "^needs_upgrade=" | cut -d= -f2)',
    '[ "$NEEDS_UPGRADE" = "false" ] && echo "Already up-to-date" && exit 0',
    'NEEDS_LABEL_UPDATE=$(echo "$COMPARE_RESULT" | grep "^needs_label_update=" | cut -d= -f2)',
    'EXISTING_PR=$(echo "$COMPARE_RESULT" | grep "^existing_pr=" | cut -d= -f2)',
    'EXISTING_BRANCH=$(echo "$COMPARE_RESULT" | grep "^existing_branch=" | cut -d= -f2)',
    'IS_NEW_VERSION=$(echo "$COMPARE_RESULT" | grep "^is_new_version=" | cut -d= -f2)',
]

TAIL_GIT = 'if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then git fetch origin "$BRANCH_NAME"; git checkout -B "$BRANCH_NAME" origin/"$BRANCH_NAME"; else git checkout -b "$BRANCH_NAME"; fi'


def header(d, name, ver_arg, use_by, up_repo, ver_type, tag_prefix, files_upd, pkg_path):
    return [
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
        f'export PKG_PATH="{pkg_path}"',
    ]


def config_version_block():
    return [
        'CONFIG_VERSION=$(get_config_version "$ADDON_DIR")',
        'echo "config_version=$CONFIG_VERSION" >> $GITHUB_OUTPUT',
    ]


def new_addon_version_block():
    return [
        'NEW_ADDON_VERSION=$(generate_calver_version "$CONFIG_VERSION")',
        'echo "new_addon_version=$NEW_ADDON_VERSION" >> $GITHUB_OUTPUT',
    ]


def git_add_block(d, files_upd):
    line = 'git add'
    for f in files_upd.split():
        line += f' "$ADDON_DIR/{f}"'
    return [line, TAIL_GIT]


for name, d, ver_arg, use_by, up_repo, ver_type, tag_prefix, files_upd, ls_repo, pkg_path in ADDONS:
    lines = header(d, name, ver_arg, use_by, up_repo, ver_type, tag_prefix, files_upd, pkg_path)

    if d == "gitea":
        # Official gitea/gitea image tracked on the "<minor>-nightly" channel.
        # Compare MAJOR.MINOR of go-gitea/gitea stable releases.
        lines += [
            'CURRENT_MINOR=$(grep -Eo "gitea/gitea:[0-9]+\\.[0-9]+" "$ADDON_DIR"/build.yaml | head -1 | sed "s/.*://" || echo "")',
            'echo "current_minor=$CURRENT_MINOR" >> $GITHUB_OUTPUT',
        ]
        lines += config_version_block()
        lines += [
            'IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_release "$UPSTREAM_REPO" "$VERSION_TYPE" "$TAG_PREFIX")"',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
            'LATEST_MINOR=$(echo "$LATEST_VERSION" | cut -d. -f1,2)',
            'echo "latest_minor=$LATEST_MINOR" >> $GITHUB_OUTPUT',
            'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_MINOR" "$RELEASE_TYPE" "$VERSION_TYPE" "$CURRENT_MINOR")',
        ]
        lines += TAIL_COMPARE
        lines += new_addon_version_block()
        lines += [
            'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_MINOR"; fi',
            'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            'ESCAPED_CURRENT=$(printf \'%s\' "$CURRENT_MINOR" | sed \'s/\\./\\\\./g\')',
            'sed -i "s|gitea/gitea:${ESCAPED_CURRENT}-nightly|gitea/gitea:${LATEST_MINOR}-nightly|g" "$ADDON_DIR"/build.yaml',
        ]
        lines += git_add_block(d, files_upd)
    elif use_by == "true":
        # linuxserver flow: compare FULL image tags (e.g. v1.13.7-ls144),
        # so ls-only rebuilds also trigger an upgrade.
        ls_arg = f' "{ls_repo}"' if ls_repo else ''
        lines += [
            'BUILD_TAG=$(get_build_yaml_tag "$ADDON_DIR")',
            "CURRENT_TAG=$(echo \"$BUILD_TAG\" | sed -E 's/^[a-z0-9]+-//' || true)",
            'echo "build_tag=$BUILD_TAG" >> $GITHUB_OUTPUT',
            'echo "current_tag=$CURRENT_TAG" >> $GITHUB_OUTPUT',
        ]
        lines += config_version_block()
        lines += [
            f'IFS="|" read -r LATEST_TAG LATEST_VERSION LATEST_BUILD RELEASE_TYPE RELEASE_URL MINOR_VERSION <<< "$(get_latest_ls_release "$ADDON_DIR" "$TAG_PREFIX"{ls_arg})"',
            'echo "latest_tag=$LATEST_TAG" >> $GITHUB_OUTPUT',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "latest_build=$LATEST_BUILD" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
            '[ -n "$MINOR_VERSION" ] && echo "minor_version=$MINOR_VERSION" >> $GITHUB_OUTPUT',
            'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_TAG" "$RELEASE_TYPE" "$VERSION_TYPE" "$CURRENT_TAG")',
        ]
        lines += TAIL_COMPARE
        lines += new_addon_version_block()
        lines += [
            'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-$LATEST_TAG"; fi',
            'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            'ESCAPED_CURRENT=$(printf \'%s\' "$CURRENT_TAG" | sed \'s/\\./\\\\./g\')',
            'sed -i "s/${ESCAPED_CURRENT}/${LATEST_TAG}/g" "$ADDON_DIR"/build.yaml',
        ]
        lines += git_add_block(d, files_upd)
    elif ver_type == "direct":
        lines += [
            f'BUILD_VERSION=$(grep -Eo "{d}[^:]*:[0-9]+\\.[0-9]+\\.[0-9]+" "$ADDON_DIR"/build.yaml | head -1 | sed "s/.*://" || echo "")',
            'echo "build_version=$BUILD_VERSION" >> $GITHUB_OUTPUT',
        ]
        lines += config_version_block()
        lines += [
            'IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_release "$UPSTREAM_REPO" "$VERSION_TYPE" "$TAG_PREFIX")"',
            'echo "latest_release=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
            'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$BUILD_VERSION")',
        ]
        lines += TAIL_COMPARE
        lines += new_addon_version_block()
        lines += [
            'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_VERSION"; fi',
            'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            f'sed -i "s|{d}/{d}-ce:[0-9][0-9.]*|{d}/{d}-ce:${{LATEST_VERSION}}|g" "$ADDON_DIR"/build.yaml',
        ]
        lines += git_add_block(d, files_upd)
    else:
        # calver / deemix / fizzy / node: Dockerfile ARG compare.
        lines += [
            'DOCKERFILE_VERSION=$(get_dockerfile_version "$ADDON_DIR" "$VERSION_ARG")',
            'echo "dockerfile_version=$DOCKERFILE_VERSION" >> $GITHUB_OUTPUT',
        ]
        lines += config_version_block()
        lines += [
            'IFS="|" read -r LATEST_VERSION RELEASE_TYPE RELEASE_URL <<< "$(get_latest_release "$UPSTREAM_REPO" "$VERSION_TYPE" "$TAG_PREFIX")"',
            'echo "latest_release=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT',
            'echo "release_type=$RELEASE_TYPE" >> $GITHUB_OUTPUT',
            'echo "release_url=$RELEASE_URL" >> $GITHUB_OUTPUT',
            'COMPARE_RESULT=$(check_pr_status "$ADDON_DIR" "$DISPLAY_NAME" "$LATEST_VERSION" "$RELEASE_TYPE" "$VERSION_TYPE" "$DOCKERFILE_VERSION")',
        ]
        lines += TAIL_COMPARE
        lines += new_addon_version_block()
        lines += [
            'if [ "$NEEDS_LABEL_UPDATE" = "true" ] && [ -n "$EXISTING_BRANCH" ]; then BRANCH_NAME="$EXISTING_BRANCH"; else BRANCH_NAME="upgrade/$ADDON_DIR-v$LATEST_VERSION"; fi',
            'echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT',
            'sed -i "s/^version: .*/version: \\"$NEW_ADDON_VERSION\\"/" "$ADDON_DIR"/config.yaml',
            'sed -i "s/ARG $VERSION_ARG=.*/ARG $VERSION_ARG=\\"$LATEST_VERSION\\"/" "$ADDON_DIR"/Dockerfile',
        ]
        lines += git_add_block(d, files_upd)

    content = "\n".join(lines) + "\n"
    path = os.path.join(UPDATES_DIR, d + ".sh")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    os.chmod(path, 0o755)
    print(f"Generated: {path}")

print(f"\nGenerated {len(ADDONS)} addon scripts in {UPDATES_DIR}")
