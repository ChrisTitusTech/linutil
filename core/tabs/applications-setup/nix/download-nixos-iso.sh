#!/bin/sh -e

. ../../common-script.sh

# NixOS ISO Download Script
# Downloads and verifies NixOS ISOs (stable/unstable, minimal/gnome)

DOWNLOAD_DIR="${HOME}/Downloads"

showMenu() {
    printf "%b\n" "${CYAN}======================================${RC}"
    printf "%b\n" "${CYAN}       NixOS ISO Downloader${RC}"
    printf "%b\n" "${CYAN}======================================${RC}"
    printf "%b\n" "1) Stable Minimal"
    printf "%b\n" "2) Stable GNOME"
    printf "%b\n" "3) Unstable Minimal"
    printf "%b\n" "4) Unstable GNOME"
    printf "%b\n" "0) Exit"
    printf "%b" "${YELLOW}Select option: ${RC}"
}

downloadISO() {
    iso_type="$1"
    channel="$2"
    
    printf "%b\n" "${YELLOW}Downloading NixOS ISO (${iso_type}, ${channel})...${RC}"
    
    if [ "$channel" = "nixos-unstable" ]; then
        printf "%b\n" "${CYAN}Resolving unstable channel...${RC}"
        base_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://channels.nixos.org/${channel}")
        version_str=$(basename "$base_url")
        version_str="${version_str#nixos-}"
        iso_name="nixos-${iso_type}-${version_str}-x86_64-linux.iso"
        iso_url="${base_url}/${iso_name}"
    else
        iso_name="latest-nixos-${iso_type}-x86_64-linux.iso"
        iso_url="https://channels.nixos.org/${channel}/${iso_name}"
    fi
    
    hash_url="${iso_url}.sha256"
    
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR" || exit 1
    
    printf "%b\n" "${YELLOW}Downloading ISO...${RC}"
    printf "%b\n" "${CYAN}URL: ${iso_url}${RC}"
    
    if ! curl -L -o "$iso_name" "$iso_url"; then
        printf "%b\n" "${RED}ISO download failed.${RC}"
        return 1
    fi
    
    printf "%b\n" "${YELLOW}Downloading checksum...${RC}"
    if ! curl -L -o "${iso_name}.sha256" "$hash_url"; then
        printf "%b\n" "${RED}Checksum download failed.${RC}"
        return 1
    fi
    
    printf "%b\n" "${YELLOW}Verifying checksum...${RC}"
    if sha256sum -c "${iso_name}.sha256"; then
        printf "%b\n" "${GREEN}Verified successfully!${RC}"
        printf "%b\n" "${GREEN}Saved to: ${DOWNLOAD_DIR}/${iso_name}${RC}"
        rm -f "${iso_name}.sha256"
    else
        printf "%b\n" "${RED}Checksum mismatch! Download may be corrupted.${RC}"
        return 1
    fi
}

mainMenu() {
    while true; do
        clear
        showMenu
        read -r choice
        
        case $choice in
            1)
                downloadISO "minimal" "nixos-24.11"
                ;;
            2)
                downloadISO "gnome" "nixos-24.11"
                ;;
            3)
                downloadISO "minimal" "nixos-unstable"
                ;;
            4)
                downloadISO "gnome" "nixos-unstable"
                ;;
            0)
                printf "%b\n" "${GREEN}Exiting...${RC}"
                exit 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid option.${RC}"
                ;;
        esac
        
        printf "%b" "${CYAN}Press Enter to continue...${RC}"
        read -r _
    done
}

checkEnv
checkCommandRequirements "curl sha256sum"
mainMenu
