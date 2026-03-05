#!/bin/sh

fallout_game="Fallout76"
fallout_common="Fallout76"
fallout_compatdata="1151340/pfx/drive_c/users/steamuser/Documents/My Games/Fallout 76"

# Find the steamapps directory that contains Fallout 76
find_steamapps_dirs() {
    [ -n "$steamapps_dir" ] && return 0

    printf "%b\n" "${YELLOW}Searching for Steam libraries with $fallout_game...${RC}"

    # Find all steamapps directories
    all_steamapps=$(find "$HOME" /mnt -type d -name "steamapps" 2>/dev/null | head -20)

    if [ -z "$all_steamapps" ]; then
        printf "%b\n" "${RED}No Steam libraries found.${RC}"
        return 1
    fi

    # Auto-select the library that has the game
    while IFS= read -r steam_dir; do
        if [ -d "$steam_dir/common/$fallout_common" ]; then
            steamapps_dir="$steam_dir"
            compatdata_path="$steam_dir/compatdata/$fallout_compatdata"
            common_path="$steam_dir/common/$fallout_common"
            printf "%b\n" "${GREEN}Found $fallout_game in $steam_dir${RC}"
            return 0
        fi
    done << EOF
$all_steamapps
EOF

    printf "%b\n" "${RED}$fallout_game not found in any Steam library.${RC}"
    return 1
}

# Helper function to copy config files with error checking
copy_files() {
    src="$1"
    dest="$2"
    desc="$3"

    [ -d "$dest" ] || mkdir -p "$dest" || {
        printf "%b\n" "${RED}Failed to create directory: $dest${RC}"
        rm -rf /tmp/fallout76-configs
        return 1
    }

    cp -r "$src"/* "$dest" || {
        printf "%b\n" "${RED}Failed to copy $desc files.${RC}"
        rm -rf /tmp/fallout76-configs
        return 1
    }
}

# Clone github to tmp then copy to compatdata_path and common_path
clone_git_repo() {
    [ -z "$compatdata_path" ] || [ -z "$common_path" ] && {
        printf "%b\n" "${RED}Error: Steam paths not initialized.${RC}"
        return 1
    }

    [ -d "/tmp/fallout76-configs" ] || {
        printf "%b\n" "${YELLOW}Cloning configuration repository...${RC}"
        git clone https://github.com/ChrisTitusTech/fallout76-configs /tmp/fallout76-configs || {
            printf "%b\n" "${RED}Failed to clone repository.${RC}"
            rm -rf /tmp/fallout76-configs
            return 1
        }
    }

    # Install settings to compatdata path
    if [ -f "/tmp/fallout76-configs/Fallout76Custom.ini" ]; then
        cp "/tmp/fallout76-configs/Fallout76Custom.ini" "$compatdata_path/Fallout76Custom.ini" || {
            printf "%b\n" "${RED}Failed to copy Fallout76Custom.ini.${RC}"
            rm -rf /tmp/fallout76-configs
            return 1
        }
        printf "%b\n" "${GREEN}Settings file installed successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: Fallout76Custom.ini not found in repository.${RC}"
    fi

    # Install mods to common game path
    if [ -d "/tmp/fallout76-configs/mods" ]; then
        copy_files "/tmp/fallout76-configs/mods" "$common_path" "mods" || return 1
        printf "%b\n" "${GREEN}Mods installed successfully to common game path.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: No mods directory found in repository.${RC}"
    fi

    printf "%b\n" "${GREEN}Configuration files copied successfully.${RC}"
    rm -rf /tmp/fallout76-configs
    return 0
}

if ! find_steamapps_dirs; then
    printf "%b\n" "${RED}Setup failed: Could not locate Steam library.${RC}"
    exit 1
fi

if ! clone_git_repo; then
    printf "%b\n" "${RED}Setup failed: Could not configure game files.${RC}"
    exit 1
fi

printf "%b\n" "${GREEN}Fallout 76 configuration completed successfully!${RC}"