#!/bin/sh
# shellcheck disable=SC2034,SC2154
# SC2034: variables set here (compatdata_path, common_path) are used by the sourcing script
# SC2154: variables referenced here (git_repo, steam_game, steam_common, steam_compatdata)
#         are set by the sourcing script before this file is sourced

. ../common-script.sh

# Derive the tmp directory from the repo name (e.g. /tmp/arc-raiders)
tmp_dir="/tmp/$(basename "$git_repo" .git)"

# Required variables – set in each game script BEFORE sourcing this file:
#   steam_game       Display name and top-level directory under steamapps/common/
#                    (e.g., "Arc Raiders")
#   steam_common     Path under steamapps/common/ – may include subdirectories
#                    (e.g., "Arc Raiders/PioneerGame/Content/Movies/Frontend/")
#   steam_compatdata Path under steamapps/compatdata/
#                    (e.g., "1808500/pfx/drive_c/users/steamuser/...")
#   git_repo         Full git clone URL for the game's configuration repository
#
# Variables derived or set automatically:
#   tmp_dir          Derived from git_repo basename (e.g., /tmp/arc-raiders)
#
# Variables set by find_steamapps_dirs() for use in clone_git_repo():
#   steamapps_dir    The steamapps directory that contains the game
#   compatdata_path  Full path: steamapps_dir/compatdata/steam_compatdata
#   common_path      Full path: steamapps_dir/common/steam_common

# Locate the steamapps directory that contains the game and populate path variables
find_steamapps_dirs() {
    [ -n "$steamapps_dir" ] && return 0

    printf "%b\n" "${YELLOW}Searching for Steam libraries with $steam_game...${RC}"

    all_steamapps=$(find "$HOME" /mnt -type d -name "steamapps" 2>/dev/null | head -20)

    if [ -z "$all_steamapps" ]; then
        printf "%b\n" "${RED}No Steam libraries found.${RC}"
        return 1
    fi

    while IFS= read -r steam_dir; do
        if [ -d "$steam_dir/common/$steam_game" ]; then
            steamapps_dir="$steam_dir"
            compatdata_path="$steam_dir/compatdata/$steam_compatdata"
            common_path="$steam_dir/common/$steam_common"
            printf "%b\n" "${GREEN}Found $steam_game in $steam_dir${RC}"
            return 0
        fi
    done << EOF
$all_steamapps
EOF

    printf "%b\n" "${RED}$steam_game not found in any Steam library.${RC}"
    return 1
}

# Copy all files from src/ into dest/, creating dest if needed.
# On failure, cleans up tmp_dir and returns 1.
copy_files() {
    src="$1"
    dest="$2"
    desc="$3"

    [ -d "$dest" ] || mkdir -p "$dest" || {
        printf "%b\n" "${RED}Failed to create directory: $dest${RC}"
        rm -rf "$tmp_dir"
        return 1
    }

    cp -r "$src"/* "$dest" || {
        printf "%b\n" "${RED}Failed to copy $desc files.${RC}"
        rm -rf "$tmp_dir"
        return 1
    }
}
