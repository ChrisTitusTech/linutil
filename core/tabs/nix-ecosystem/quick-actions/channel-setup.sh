#!/bin/sh -e

. ../../common-script.sh

getStableVersion() {
    version=$(curl -sLI https://channels.nixos.org/nixos-stable -o /dev/null -w '%{url_effective}' 2>/dev/null | grep -oE 'nixos-[0-9]+\.[0-9]+' | sed 's/nixos-//' | head -1)
    if [ -z "$version" ]; then
        version="24.11"
    fi
    printf "%s" "$version"
}

addChannel() {
    STABLE_VERSION=$(getStableVersion)

    printf "%b\n" ""
    printf "%b\n" "${CYAN}Select channel to add:${RC}"
    printf "%b\n" "  1) nixpkgs-unstable  (rolling release, latest packages)"
    printf "%b\n" "  2) nixos-${STABLE_VERSION} stable  (current stable release)"
    printf "%b\n" "  3) home-manager      (user package/dotfile management)"
    printf "%b\n" "  0) Cancel"
    printf "%b" "${YELLOW}Select: ${RC}"
    read -r choice

    case "$choice" in
        1)
            printf "%b\n" "${YELLOW}Adding nixpkgs-unstable...${RC}"
            nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
            nix-channel --update nixpkgs-unstable
            printf "%b\n" "${GREEN}✓ nixpkgs-unstable added.${RC}"
            ;;
        2)
            printf "%b\n" "${YELLOW}Adding nixos-${STABLE_VERSION}...${RC}"
            nix-channel --add "https://nixos.org/channels/nixos-${STABLE_VERSION}" "nixos-${STABLE_VERSION}"
            nix-channel --update "nixos-${STABLE_VERSION}"
            printf "%b\n" "${GREEN}✓ nixos-${STABLE_VERSION} added.${RC}"
            ;;
        3)
            printf "%b\n" "${YELLOW}Adding home-manager...${RC}"
            nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
            nix-channel --update home-manager
            printf "%b\n" "${GREEN}✓ home-manager added.${RC}"
            ;;
        0)
            printf "%b\n" "${YELLOW}Cancelled.${RC}"
            return 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid option.${RC}"
            return 1
            ;;
    esac
}

removeChannel() {
    channels=$(nix-channel --list 2>/dev/null)

    if [ -z "$channels" ]; then
        printf "%b\n" "${YELLOW}No channels configured.${RC}"
        return 0
    fi

    printf "%b\n" ""
    printf "%b\n" "${CYAN}Current channels:${RC}"
    printf "%s\n" "$channels"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Enter channel name to remove (or empty to cancel): ${RC}"
    read -r target

    if [ -z "$target" ]; then
        printf "%b\n" "${YELLOW}Cancelled.${RC}"
        return 0
    fi

    if echo "$channels" | grep -q "^${target} "; then
        nix-channel --remove "$target"
        printf "%b\n" "${GREEN}✓ Channel '${target}' removed.${RC}"
    else
        printf "%b\n" "${RED}Channel '${target}' not found.${RC}"
        return 1
    fi
}

channelSetup() {
    if ! command_exists nix-channel; then
        printf "%b\n" "${RED}Nix is not installed.${RC}"
        return 1
    fi

    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════
  NIX CHANNEL SETUP
══════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"

    printf "%b\n" "${CYAN}Current channels:${RC}"
    nix-channel --list || printf "%b\n" "  (none)"
    printf "%b\n" ""

    printf "%b\n" "  1) Add a channel"
    printf "%b\n" "  2) Remove a channel"
    printf "%b\n" "  3) Update all channels"
    printf "%b\n" "  4) List channels"
    printf "%b\n" "  0) Exit"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Select: ${RC}"
    read -r choice

    case "$choice" in
        1) addChannel ;;
        2) removeChannel ;;
        3)
            printf "%b\n" "${YELLOW}Updating all channels...${RC}"
            nix-channel --update
            printf "%b\n" "${GREEN}✓ Channels updated.${RC}"
            ;;
        4)
            printf "%b\n" ""
            printf "%b\n" "${CYAN}Channels:${RC}"
            nix-channel --list || printf "%b\n" "  (none)"
            ;;
        0)
            printf "%b\n" "${YELLOW}Done.${RC}"
            return 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid option.${RC}"
            return 1
            ;;
    esac
}

checkArch
channelSetup
