#!/bin/sh

steam_game="Starfield"
steam_common="Starfield"
steam_compatdata="1716740/pfx/drive_c/users/steamuser/Documents/My Games/Starfield/"
git_repo="https://github.com/ChrisTitusTech/starfield-config"

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
    if [ -f "$tmp_dir/StarfieldCustom.ini" ]; then
        cp "$tmp_dir/StarfieldCustom.ini" "$compatdata_path/StarfieldCustom.ini" || {
            printf "%b\n" "${RED}Failed to copy StarfieldCustom.ini.${RC}"
            rm -rf "$tmp_dir"
            return 1
        }
        printf "%b\n" "${GREEN}Settings file installed successfully.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: StarfieldCustom.ini not found in repository.${RC}"
    fi

    # Install mods to common game path
    if [ -d "$tmp_dir" ]; then
        copy_files "$tmp_dir" "$common_path" "mod" || return 1
        printf "%b\n" "${GREEN}Mods installed successfully to common game path.${RC}"
    else
        printf "%b\n" "${YELLOW}Warning: No directory found in repository.${RC}"
    fi

    stock_size_min_bytes=94371840 # 90 MiB
    starfield_exe_size=$(wc -c < "$common_path/Starfield.exe" 2>/dev/null) || {
        printf "%b\n" "${RED}Failed to read Starfield.exe size.${RC}"
        rm -rf "$tmp_dir"
        return 1
    }

    if [ "$starfield_exe_size" -gt "$stock_size_min_bytes" ]; then
        printf "%b\n" "${RED}Overwriting Starfield-STOCK.exe: New Starfield EXE detected.${RC}"
        rm -rf "$tmp_dir"
        cp -f "$common_path/Starfield.exe" "$common_path/Starfield-STOCK.exe" || {
            printf "%b\n" "${RED}Failed to backup Starfield Stock executable.${RC}"
            rm -rf "$tmp_dir"
            return 1
        }
    fi
   

    cp -f "$common_path/sfse_loader.exe" "$common_path/Starfield.exe" || {
        printf "%b\n" "${RED}Failed to replace executable with mod loader.${RC}"
        cp -f "$common_path/Starfield-STOCK.exe" "$common_path/Starfield.exe"
        rm -rf "$tmp_dir"
        return 1
    }

    printf "%b\n" "${GREEN}SFSE executable replaced Starfield.exe successfully.${RC}"

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

printf "%b\n" "${GREEN}Starfield configuration completed successfully!${RC}"