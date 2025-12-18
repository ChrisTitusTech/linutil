#!/bin/sh


steam_game="Arc Raiders"
steam_common="Arc Raiders/PioneerGame/Content/Movies/Frontend/"
steam_compatdata="1808500/pfx/drive_c/users/steamuser/Local Settings/Application Data/PioneerGame/Saved/Config/WindowsClient/"

# Find the steamapps directory that contains the game
find_steamapps_dirs() {
    [ -n "$steamapps_dir" ] && return 0
    
    printf "%b\n" "${YELLOW}Searching for Steam libraries with $steam_game...${RC}"
    
    # Find all steamapps directories
    all_steamapps=$(find "$HOME" /mnt -type d -name "steamapps" 2>/dev/null | head -20)
    
    if [ -z "$all_steamapps" ]; then
        printf "%b\n" "${RED}No Steam libraries found.${RC}"
        return 1
    fi
    
    # Auto-select the library that has the game
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

# Helper function to copy config files with error checking
copy_files() {
    src="$1"
    dest="$2"
    desc="$3"
    
    [ -d "$dest" ] || mkdir -p "$dest" || {
        printf "%b\n" "${RED}Failed to create directory: $dest${RC}"
        rm -rf /tmp/arc-raiders
        return 1
    }
    
    cp -r "$src"/* "$dest" || {
        printf "%b\n" "${RED}Failed to copy $desc files.${RC}"
        rm -rf /tmp/arc-raiders
        return 1
    }
}

# Clone github to tmp then copy to compatdata_path and common_path
clone_git_repo() {
    [ -z "$compatdata_path" ] || [ -z "$common_path" ] && {
        printf "%b\n" "${RED}Error: Steam paths not initialized.${RC}"
        return 1
    }

    [ -d "/tmp/arc-raiders" ] || {
        printf "%b\n" "${YELLOW}Cloning configuration repository...${RC}"
        git clone https://github.com/christitustech/arc-raiders.git /tmp/arc-raiders || {
            printf "%b\n" "${RED}Failed to clone repository.${RC}"
            rm -rf /tmp/arc-raiders
            return 1
        }
    }

    printf "%b\n" "${YELLOW}Copying configuration files...${RC}"
    copy_files "/tmp/arc-raiders/compatdata" "$compatdata_path" "compatdata" || return 1
    # Change Engine.ini to be read-only to prevent game from overwriting settings
    chmod 444 "$compatdata_path/Engine.ini"
    copy_files "/tmp/arc-raiders/common" "$common_path" "common" || return 1

    printf "%b\n" "${GREEN}Configuration files copied successfully.${RC}"
    rm -rf /tmp/arc-raiders
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

printf "%b\n" "${GREEN}Arc Raiders configuration completed successfully!${RC}"