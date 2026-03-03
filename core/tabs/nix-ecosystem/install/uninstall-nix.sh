#!/bin/sh -e

. ../../common-script.sh

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

backupNixConfig() {
    BACKUP_DIR="$HOME/.nix-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    printf "%b\n" "${YELLOW}Backing up Nix config to ${BACKUP_DIR}...${RC}"
    
    # System config
    if [ -f /etc/nix/nix.conf ]; then
        "$ESCALATION_TOOL" cp /etc/nix/nix.conf "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # User configs
    [ -f "$HOME/.nix-channels" ] && cp "$HOME/.nix-channels" "$BACKUP_DIR/"
    [ -f "$HOME/.config/nix/nix.conf" ] && cp "$HOME/.config/nix/nix.conf" "$BACKUP_DIR/"
    
    # List installed packages for reference
    if command_exists nix-env; then
        nix-env -q > "$BACKUP_DIR/installed-packages.txt" 2>/dev/null || true
    fi
    
    # Flake registry if exists
    if [ -f "$HOME/.config/nix/registry.json" ]; then
        cp "$HOME/.config/nix/registry.json" "$BACKUP_DIR/"
    fi
    
    printf "%b\n" "${GREEN}✓ Config backed up to ${BACKUP_DIR}${RC}"
    printf "%b\n" ""
}

detectInstaller() {
    if [ -x "/nix/nix-installer" ]; then
        printf "determinate"
    elif [ -x "/nix/lix-installer" ]; then
        printf "lix"
    else
        printf "manual"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

uninstallNix() {
    printf "%b\n" "${CYAN}╔════════════════════════════════════════════════════════════════╗${RC}"
    printf "%b\n" "${CYAN}║  NIX/LIX UNINSTALLER                                           ║${RC}"
    printf "%b\n" "${CYAN}╚════════════════════════════════════════════════════════════════╝${RC}"
    printf "%b\n" ""
    
    # Check if Nix is installed
    if ! command_exists nix && [ ! -d "/nix" ]; then
        printf "%b\n" "${RED}Nix does not appear to be installed.${RC}"
        return 1
    fi
    
    # Detect installer type
    INSTALLER_TYPE=$(detectInstaller)
    printf "%b\n" "${CYAN}Detected installer: ${YELLOW}${INSTALLER_TYPE}${RC}"
    printf "%b\n" ""
    
    # === FIRST GATE: Are you sure? ===
    printf "%b\n" "${RED}╔════════════════════════════════════════════════════════════════╗${RC}"
    printf "%b\n" "${RED}║  WARNING: This will permanently remove:                        ║${RC}"
    printf "%b\n" "${RED}║                                                                ║${RC}"
    printf "%b\n" "${RED}║    • All Nix/Lix packages in /nix/store                        ║${RC}"
    printf "%b\n" "${RED}║    • All channels and flake registry                           ║${RC}"
    printf "%b\n" "${RED}║    • Your nix.conf settings                                    ║${RC}"
    printf "%b\n" "${RED}║    • Home Manager config (if installed via Nix)                ║${RC}"
    printf "%b\n" "${RED}║                                                                ║${RC}"
    printf "%b\n" "${RED}╚════════════════════════════════════════════════════════════════╝${RC}"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Are you sure you want to uninstall? [y/N]: ${RC}"
    read -r confirm
    case "$confirm" in
        [yY]|[yY][eE][sS]) : ;;
        *) 
            printf "%b\n" "${GREEN}Uninstall cancelled.${RC}"
            return 0 
            ;;
    esac
    
    # === SECOND GATE: Backup option ===
    printf "%b\n" ""
    printf "%b" "${CYAN}Would you like to backup your config first? [y/N]: ${RC}"
    read -r backup_choice
    case "$backup_choice" in
        [yY]|[yY][eE][sS])
            backupNixConfig
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping backup.${RC}"
            printf "%b\n" ""
            ;;
    esac
    
    # === UNINSTALL ===
    case "$INSTALLER_TYPE" in
        determinate)
            printf "%b\n" "${YELLOW}Running Determinate uninstaller...${RC}"
            "$ESCALATION_TOOL" /nix/nix-installer uninstall
            printf "%b\n" "${GREEN}✓ Uninstalled via Determinate installer.${RC}"
            ;;
        lix)
            printf "%b\n" "${YELLOW}Running Lix uninstaller...${RC}"
            "$ESCALATION_TOOL" /nix/lix-installer uninstall
            printf "%b\n" "${GREEN}✓ Uninstalled via Lix installer.${RC}"
            ;;
        manual)
            printf "%b\n" "${YELLOW}No installer binary found, performing manual removal...${RC}"
            printf "%b\n" ""
            
            # Stop services
            if command_exists systemctl; then
                printf "%b\n" "${YELLOW}Stopping Nix daemon...${RC}"
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
            
            printf "%b\n" "${YELLOW}Removing user Nix files...${RC}"
            rm -rf "$HOME/.nix-profile"
            rm -rf "$HOME/.nix-channels"
            rm -rf "$HOME/.nix-defexpr"
            rm -rf "$HOME/.config/nix"
            rm -rf "$HOME/.cache/nix"
            rm -rf "$HOME/.local/state/nix"
            
            # Clean up profile entries
            printf "%b\n" "${YELLOW}Cleaning shell profiles...${RC}"
            "$ESCALATION_TOOL" rm -f /etc/profile.d/nix.sh 2>/dev/null || true
            "$ESCALATION_TOOL" rm -f /etc/profile.d/nix-daemon.sh 2>/dev/null || true
            
            printf "%b\n" "${GREEN}✓ Manual uninstall complete.${RC}"
            ;;
    esac
    
    printf "%b\n" ""
    printf "%b\n" "${GREEN}╔════════════════════════════════════════════════════════════════╗${RC}"
    printf "%b\n" "${GREEN}║  Nix has been uninstalled.                                     ║${RC}"
    printf "%b\n" "${GREEN}╚════════════════════════════════════════════════════════════════╝${RC}"
    printf "%b\n" ""
    printf "%b\n" "${CYAN}Restart your shell or log out and back in to complete cleanup.${RC}"
    
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        printf "%b\n" "${CYAN}Your config backup is at: ${YELLOW}${BACKUP_DIR}${RC}"
    fi
}

checkArch
checkEscalationTool
uninstallNix
