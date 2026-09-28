#!/bin/bash
# shellcheck disable=SC2086,SC2154
# Shared library for auto-upgrade operations
# Source this file from .updates/<addon>.sh scripts

set -euo pipefail

# Authenticated GitHub API calls: GH_TOKEN (already exported by the workflows)
# lifts the harsh 60 req/h unauthenticated rate limit shared by Actions runners.
# shellcheck disable=SC2034
GH_API_HEADERS=()
if [ -n "${GH_TOKEN:-}" ]; then
    GH_API_HEADERS=(-H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json")
fi

########################################
# Shared functions for auto-upgrade
########################################

# Get the addon directory (defaults to current working directory name)
get_addon_dir() {
    echo "${ADDON_DIR:-$(basename "$(pwd)")}"
}

# Extract version from Dockerfile ARG (fallback to ENV for legacy files)
get_dockerfile_version() {
    local addon_dir="$1"
    local version_arg="$2"
    (grep -E "(ARG|ENV) ${version_arg}=" "${addon_dir}/Dockerfile" | head -1 | sed 's/.*=//' | sed 's/"//g' | sed "s/'//g" | sed 's/[[:space:]]*//g' | sed 's/\r//g' || true)
}

# Extract version from build.yaml (linuxserver style)
get_build_yaml_version() {
    local addon_dir="$1"
    (grep -E 'lscr.io/linuxserver/' "${addon_dir}/build.yaml" | head -1 | sed 's/.*://' | sed 's/[[:space:]]*//g' | sed 's/"//g' | sed 's/\r//g' || true)
}

# Extract version from config.yaml
get_config_version() {
    local addon_dir="$1"
    (grep -E '^version:' "${addon_dir}/config.yaml" | sed 's/version: "//' | sed 's/"//' | sed 's/[[:space:]]*//g' | sed 's/\r//g' || true)
}

# Extract build.yaml tag for linuxserver
get_build_yaml_tag() {
    local addon_dir="$1"
    (grep -E 'lscr.io/linuxserver/' "${addon_dir}/build.yaml" | head -1 | sed 's/.*://' | sed 's/[[:space:]]*//g' | sed 's/"//g' | sed 's/\r//g' || true)
}

# Compare two versions
# version_type "fizzy" (commit-sha based): any difference means new
is_new_version() {
    local current="$1"
    local latest="$2"
    local version_type="${3:-}"
    if [ -z "$current" ]; then
        return 0
    fi
    if [ "$current" = "$latest" ]; then
        return 1
    fi
    if [ "$version_type" = "fizzy" ]; then
        return 0
    fi
    if [ "$(printf '%s\n' "$latest" "$current" | sort -V | head -n1)" = "$current" ] && [ "$current" != "$latest" ]; then
        return 0
    fi
    return 1
}

# Get latest GitHub release
# Args: upstream_repo, version_type, [tag_prefix] (e.g. "v" for tags like v1.2.3)
# Output: "<version>|<release_type>|<release_url>" (version has tag_prefix stripped)
get_latest_release() {
    local upstream_repo="$1"
    local version_type="$2"
    local tag_prefix="${3:-}"
    local result=""

    if [ "$version_type" = "direct" ]; then
        local data=$(curl -s "${GH_API_HEADERS[@]}" "https://api.github.com/repos/${upstream_repo}/releases")
        # Validate it's an array
        if ! echo "$data" | jq -e 'type == "array"' > /dev/null 2>&1; then
            echo "ERROR: GitHub API did not return a release array for ${upstream_repo} (repo renamed, deleted or rate-limited?)" >&2
            return 1
        fi
        local tag=$(echo "$data" | jq -r '.[].tag_name' | while read -r t; do
            if [[ "$t" =~ ^${tag_prefix}[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "$t"
                break
            fi
        done)
        if [ -z "$tag" ]; then
            echo "ERROR: no release tag matching '${tag_prefix}X.Y.Z' found for ${upstream_repo}" >&2
            return 1
        fi
        local latest="${tag#"$tag_prefix"}"
        local release_info=$(echo "$data" | jq ".[] | select(.tag_name==\"$tag\")")
        local is_prerelease=$(echo "$release_info" | jq -r '.prerelease')
        local release_url=$(echo "$release_info" | jq -r '.html_url')
        local release_type="latest"
        if [ "$is_prerelease" = "true" ]; then
            release_type="pre-release"
        fi
        echo "$latest|$release_type|$release_url"
    elif [ "$version_type" = "deemix" ]; then
        local tag=$(curl -fsSL "${GH_API_HEADERS[@]}" "https://api.github.com/repos/${upstream_repo}/releases/latest" | jq -r '.tag_name')
        local latest="${tag##*@}"
        local release_url="https://github.com/${upstream_repo}/releases/tag/$tag"
        echo "$latest|latest|$release_url"
    elif [ "$version_type" = "fizzy" ]; then
        # basecamp/fizzy releases are tagged fizzy@<commit-sha>
        local data=$(curl -s "${GH_API_HEADERS[@]}" "https://api.github.com/repos/${upstream_repo}/releases")
        if ! echo "$data" | jq -e 'type == "array"' > /dev/null 2>&1; then
            echo "ERROR: GitHub API did not return a release array for ${upstream_repo} (repo renamed, deleted or rate-limited?)" >&2
            return 1
        fi
        local tag=$(echo "$data" | jq -r '.[].tag_name' | while read -r t; do
            if [[ "$t" =~ ^fizzy@[0-9a-f]+$ ]]; then
                echo "$t"
                break
            fi
        done)
        if [ -z "$tag" ]; then
            echo "ERROR: no release tag matching 'fizzy@<sha>' found for ${upstream_repo}" >&2
            return 1
        fi
        local latest="${tag#fizzy@}"
        local release_info=$(echo "$data" | jq ".[] | select(.tag_name==\"$tag\")")
        local is_prerelease=$(echo "$release_info" | jq -r '.prerelease')
        local release_url=$(echo "$release_info" | jq -r '.html_url')
        local release_type="latest"
        if [ "$is_prerelease" = "true" ]; then
            release_type="pre-release"
        fi
        echo "$latest|$release_type|$release_url"
    elif [ "$version_type" = "node" ]; then
        # version read from a package.json on the default branch
        # (e.g. requestly/interceptor app/package.json). Path from $PKG_PATH.
        local pkg_path="${PKG_PATH:-package.json}"
        local pkg_json=$(curl -fsSL "https://raw.githubusercontent.com/${upstream_repo}/HEAD/${pkg_path}" 2>/dev/null || curl -fsSL "https://raw.githubusercontent.com/${upstream_repo}/master/${pkg_path}" 2>/dev/null || curl -fsSL "https://raw.githubusercontent.com/${upstream_repo}/main/${pkg_path}" 2>/dev/null || true)
        local latest=$(echo "$pkg_json" | jq -r '.version // empty' 2>/dev/null || true)
        if [ -z "$latest" ]; then
            echo "ERROR: could not read version from ${pkg_path} on ${upstream_repo} default branch" >&2
            return 1
        fi
        echo "$latest|latest|https://github.com/${upstream_repo}/commits/HEAD/${pkg_path}"
    else
        local data=$(curl -s "${GH_API_HEADERS[@]}" "https://api.github.com/repos/${upstream_repo}/releases")
        if ! echo "$data" | jq -e 'type == "array"' > /dev/null 2>&1; then
            echo "ERROR: GitHub API did not return a release array for ${upstream_repo} (repo renamed, deleted or rate-limited?)" >&2
            return 1
        fi
        local tag=$(echo "$data" | jq -r '.[].tag_name' | while read -r t; do
            if [[ "$t" =~ ^${tag_prefix}[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "$t"
                break
            fi
        done)
        if [ -z "$tag" ]; then
            echo "ERROR: no release tag matching '${tag_prefix}X.Y.Z' found for ${upstream_repo}" >&2
            return 1
        fi
        local latest="${tag#"$tag_prefix"}"
        local release_info=$(echo "$data" | jq ".[] | select(.tag_name==\"$tag\")")
        local is_prerelease=$(echo "$release_info" | jq -r '.prerelease')
        local release_url=$(echo "$release_info" | jq -r '.html_url')
        local release_type="latest"
        if [ "$is_prerelease" = "true" ]; then
            release_type="pre-release"
        fi
        echo "$latest|$release_type|$release_url"
    fi
}

# Get latest linuxserver release
# Matches tags like 3.1.0.4875-ls42, v1.13.7-ls146, v26.3-ls265, nightly-3.1.6.5078-ls218
# Output: "<full_tag>|<version>|<ls_build>|<release_type>|<release_url>|<minor_version>"
get_latest_ls_release() {
    local addon_dir="$1"
    local tag_prefix="$2"
    local ls_repo="${3:-docker-${addon_dir}}"
    local data=""
    local repo=""
    for repo in "linuxserver/${ls_repo}-ls" "linuxserver/${ls_repo}"; do
        data=$(curl -s "${GH_API_HEADERS[@]}" "https://api.github.com/repos/${repo}/releases")
        if echo "$data" | jq -e 'type == "array"' > /dev/null 2>&1; then
            break
        fi
        data=""
    done
    if [ -z "$data" ]; then
        echo "ERROR: GitHub API did not return a release array for linuxserver/${ls_repo} (repo renamed, deleted or rate-limited?)" >&2
        return 1
    fi
    local latest=$(echo "$data" | jq -r '.[].tag_name' | while read -r tag; do
        if [[ "$tag" =~ ^${tag_prefix}v?[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?-ls[0-9]+$ ]]; then
            echo "$tag"
            break
        fi
    done)
    if [ -z "$latest" ]; then
        echo "ERROR: no linuxserver tag matching '${tag_prefix}[v]X.Y[.Z[.W]]-lsN' found for ${addon_dir}" >&2
        return 1
    fi
    local release_info=$(echo "$data" | jq ".[] | select(.tag_name==\"$latest\")")
    local version=$(echo "$latest" | sed "s/^${tag_prefix}//" | sed 's/-ls[0-9]*$//')
    local build=$(echo "$latest" | grep -oE 'ls[0-9]+$')
    local minor_version=$(echo "$version" | cut -d. -f1,2)
    local is_prerelease=$(echo "$release_info" | jq -r '.prerelease')
    local release_url=$(echo "$release_info" | jq -r '.html_url')
    local release_type="latest"
    if [ "$is_prerelease" = "true" ]; then
        release_type="pre-release"
    fi
    echo "$latest|$version|$build|$release_type|$release_url|$minor_version"
}

# Generate CalVer addon version
generate_calver_version() {
    local current_version="$1"
    local current_year=$(date +%y)
    local current_month=$(date +%m)
    current_month=${current_month#0}
    local current_patch=$(echo "$current_version" | cut -d. -f3)
    local current_ym=$(echo "$current_version" | cut -d. -f1,2)
    local new_ym="$current_year.$current_month"
    local new_patch
    if [ "$current_ym" = "$new_ym" ]; then
        new_patch=$((current_patch + 1))
    else
        new_patch=1
    fi
    echo "$new_ym.$new_patch"
}

# Check existing PR and determine if upgrade is needed
check_pr_status() {
    local addon_dir="$1"
    local display_name="$2"
    local latest_version="$3"
    local release_type="$4"
    local version_type="$5"
    local current_build_version="$6"

    if [ -z "$latest_version" ]; then
        echo "ERROR: empty latest version for ${display_name} (${addon_dir}): upstream release lookup failed (check UPSTREAM_REPO/VERSION_TYPE/TAG_PREFIX in .updates/${addon_dir}.sh, or delete that script to exclude it from auto-upgrades)" >&2
        exit 1
    fi

    local is_new_version=false
    local compare_current="$current_build_version"
    if [ "$version_type" = "direct" ]; then
        compare_current="$current_build_version"
    fi

    if is_new_version "$compare_current" "$latest_version" "$version_type"; then
        is_new_version=true
    fi

    local needs_label_update=false
    local existing_pr=""
    local existing_branch=""

    if [ "$is_new_version" = "false" ]; then
        local pr_list=$(gh pr list --search "${display_name} ${latest_version}" --json number,labels,headRefName --jq '.[]' 2>/dev/null || echo "")
        if [ -n "$pr_list" ]; then
            while IFS= read -r pr; do
                local pr_number=$(echo "$pr" | jq -r '.number')
                local pr_labels=$(echo "$pr" | jq -r '.labels[].name')
                local pr_branch=$(echo "$pr" | jq -r '.headRefName')
                if [ "$release_type" = "latest" ] && echo "$pr_labels" | grep -q "pre-release"; then
                    needs_label_update=true
                    existing_pr="$pr_number"
                    existing_branch="$pr_branch"
                    break
                elif [ "$release_type" = "pre-release" ] && echo "$pr_labels" | grep -q "latest"; then
                    needs_label_update=true
                    existing_pr="$pr_number"
                    existing_branch="$pr_branch"
                    break
                fi
            done <<< "$pr_list"
        fi
    fi

    if [ "$is_new_version" = "true" ] || [ "$needs_label_update" = "true" ]; then
        echo "needs_upgrade=true"
        echo "needs_label_update=$needs_label_update"
        echo "existing_pr=$existing_pr"
        echo "existing_branch=$existing_branch"
        echo "is_new_version=$is_new_version"
    else
        echo "needs_upgrade=false"
    fi
}


