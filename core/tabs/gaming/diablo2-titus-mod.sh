#!/bin/sh

steam_game="Diablo II Resurrected"
steam_common="Diablo II Resurrected/mods"
steam_compatdata="2536520/pfx/drive_c/users/steamuser/Saved Games/Diablo II Resurrected"
git_repo="https://github.com/ChrisTitusTech/d2r-loot-filter"

# shellcheck source=core/tabs/gaming/common-steam-script.sh
. ./common-steam-script.sh

# Clone git repo then copy to common_path (mods folder)
clone_git_repo() {
    if [ -z "$common_path" ]; then
        printf "%b\n" "${RED}Error: Steam paths not initialized.${RC}"
        return 1
    fi

    [ -d "$tmp_dir" ] || {
        printf "%b\n" "${YELLOW}Cloning loot filter repository...${RC}"
        git clone "$git_repo" "$tmp_dir" || {
            printf "%b\n" "${RED}Failed to clone repository.${RC}"
            rm -rf "$tmp_dir"
            return 1
        }
    }

    printf "%b\n" "${YELLOW}Copying mod files...${RC}"
    copy_files "$tmp_dir" "$common_path" "loot filter" || return 1

    printf "%b\n" "${GREEN}Loot filter installed successfully.${RC}"
    rm -rf "$tmp_dir"
    return 0
}

if ! find_steamapps_dirs; then
    printf "%b\n" "${RED}Setup failed: Could not locate Steam library.${RC}"
    exit 1
fi

if ! clone_git_repo; then
    printf "%b\n" "${RED}Setup failed: Could not install loot filter.${RC}"
    exit 1
fi

printf "%b\n" "${GREEN}Diablo II: Resurrected loot filter installed successfully!${RC}"
printf "%b\n" "${YELLOW}To complete the setup, add the following Steam launch options:${RC}"
printf "%b\n" "1. Right-click Diablo II: Resurrected in your Steam library"
printf "%b\n" "2. Select 'Properties'"
printf "%b\n" "3. In the 'Launch Options' field, enter: %command% -mod lootfilter -txt"
printf "%b\n" "4. Close the Properties window and launch the game"