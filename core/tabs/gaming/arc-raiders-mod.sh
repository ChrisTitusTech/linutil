#!/bin/sh

steam_game="Arc Raiders"
steam_common="Arc Raiders/PioneerGame/Content/Movies/Frontend/"
steam_compatdata="1808500/pfx/drive_c/users/steamuser/Local Settings/Application Data/PioneerGame/Saved/Config/WindowsClient/"
git_repo="https://github.com/christitustech/arc-raiders.git"

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

    printf "%b\n" "${YELLOW}Copying configuration files...${RC}"
    copy_files "$tmp_dir/compatdata" "$compatdata_path" "compatdata" || return 1
    # Change Engine.ini to be read-only to prevent game from overwriting settings
    chmod 444 "$compatdata_path/Engine.ini"
    copy_files "$tmp_dir/common" "$common_path" "common" || return 1

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

printf "%b\n" "${GREEN}Arc Raiders configuration completed successfully!${RC}"