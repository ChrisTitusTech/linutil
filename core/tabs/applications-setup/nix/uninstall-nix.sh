#!/bin/sh -e

. ../../common-script.sh

uninstallNix() {
    printf "%b\n" "${YELLOW}Uninstalling Nix/Lix...${RC}"

    if ! command_exists nix && [ ! -d "/nix" ]; then
        printf "%b\n" "${RED}Nix does not appear to be installed.${RC}"
        return 1
    fi

    printf "%b\n" "${RED}WARNING: This will remove Nix and all packages installed with it.${RC}"
    printf "%b" "${YELLOW}Continue? (y/N): ${RC}"
    read -r confirm
    case "$confirm" in
        [yY]|[yY][eE][sS]) : ;;
        *) printf "%b\n" "${YELLOW}Aborted.${RC}"; return 0 ;;
    esac

    # Try Lix installer first
    if [ -x "/nix/lix-installer" ]; then
        printf "%b\n" "${CYAN}Detected Lix installer, using it...${RC}"
        "$ESCALATION_TOOL" /nix/lix-installer uninstall
        printf "%b\n" "${GREEN}Uninstalled via Lix installer.${RC}"
        return 0
    fi

    # Try Determinate installer
    if [ -x "/nix/nix-installer" ]; then
        printf "%b\n" "${CYAN}Detected Determinate installer, using it...${RC}"
        "$ESCALATION_TOOL" /nix/nix-installer uninstall
        printf "%b\n" "${GREEN}Uninstalled via Determinate installer.${RC}"
        return 0
    fi

    # Manual fallback
    printf "%b\n" "${YELLOW}No installer found, performing manual removal...${RC}"

    # Stop daemon if running
    if command_exists systemctl; then
        "$ESCALATION_TOOL" systemctl stop nix-daemon.service 2>/dev/null || true
        "$ESCALATION_TOOL" systemctl disable nix-daemon.service 2>/dev/null || true
        "$ESCALATION_TOOL" systemctl stop nix-daemon.socket 2>/dev/null || true
        "$ESCALATION_TOOL" systemctl disable nix-daemon.socket 2>/dev/null || true
    fi

    # Remove directories
    printf "%b\n" "${YELLOW}Removing /nix...${RC}"
    "$ESCALATION_TOOL" rm -rf /nix

    printf "%b\n" "${YELLOW}Removing /etc/nix...${RC}"
    "$ESCALATION_TOOL" rm -rf /etc/nix

    printf "%b\n" "${YELLOW}Removing user files...${RC}"
    rm -rf "$HOME/.nix-profile" "$HOME/.nix-channels" "$HOME/.nix-defexpr"

    # Clean up profile entries
    printf "%b\n" "${YELLOW}Cleaning shell profiles...${RC}"
    "$ESCALATION_TOOL" rm -f /etc/profile.d/nix.sh 2>/dev/null || true
    "$ESCALATION_TOOL" rm -f /etc/bash.bashrc.backup-before-nix 2>/dev/null || true

    printf "%b\n" "${GREEN}Nix uninstalled.${RC}"
    printf "%b\n" "${CYAN}Restart your shell or log out and back in.${RC}"
}

checkEnv
checkEscalationTool
uninstallNix
