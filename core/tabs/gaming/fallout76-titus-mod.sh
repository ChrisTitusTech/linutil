#!/bin/sh

steam_game="Fallout76"
steam_common="Fallout76"
steam_compatdata="1151340/pfx/drive_c/users/steamuser/Documents/My Games/Fallout 76"
git_repo="https://github.com/ChrisTitusTech/fallout76-configs"

# shellcheck source=core/tabs/gaming/common-steam-script.sh
. ./common-steam-script.sh

# Clone git repo then copy to compatdata_path and common_path
clone_git_repo() {
    if [ -z "$compatdata_path" ] || [ -z "$common_path" ]; then
        printf "%b\n" "${RED}Error: Steam paths not initialized.${RC}"
        return 1
    fi

    [ -d "$tmp_dir" ] || {
        printf "%b\n" "${YELLOW}Cloning configuration repository...${RC}"
        git clone "$git_repo" "$tmp_dir" || {
            printf "%b\n" "${RED}Failed to clone repository.${RC}"
            rm -rf "$tmp_dir"
            return 1
        }
    }

    # Install settings to compatdata path
    if [ -f "$tmp_dir/Fallout76Custom.ini" ]; then
        cp "$tmp_dir/Fallout76Custom.ini" "$compatdata_path/Fallout76Custom.ini" || {
            printf "%b\n" "${RED}Failed to copy Fallout76Custom.ini.${RC}"
            rm -rf "$tmp_dir"
            return 1
        }
        printf "%b\n" "${GREEN}Settings file installed successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: Fallout76Custom.ini not found in repository.${RC}"
    fi

    # Install mods to common game path
    if [ -d "$tmp_dir/mods" ]; then
        copy_files "$tmp_dir/mods" "$common_path" "mods" || return 1
        printf "%b\n" "${GREEN}Mods installed successfully to common game path.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: No mods directory found in repository.${RC}"
    fi

    printf "%b\n" "${GREEN}Configuration files copied successfully.${RC}"
    rm -rf "$tmp_dir"
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