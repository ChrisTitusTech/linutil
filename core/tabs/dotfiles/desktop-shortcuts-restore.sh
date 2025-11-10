#!/bin/sh -e

. ../common-script.sh

DOTFILES_DIR="$HOME/.dotfiles"

detectDesktop() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        printf "%b\n" "${CYAN}Detected desktop environment: $XDG_CURRENT_DESKTOP${RC}"
        return 0
    elif command_exists gnome-shell; then
        printf "%b\n" "${CYAN}Detected GNOME desktop environment${RC}"
        return 0
    elif command_exists plasmashell; then
        printf "%b\n" "${CYAN}Detected KDE Plasma desktop environment${RC}"
        return 0
    else
        printf "%b\n" "${YELLOW}Could not detect desktop environment${RC}"
        return 1
    fi
}

restoreGnomeShortcuts() {
    if ! command_exists gsettings; then
        printf "%b\n" "${RED}gsettings not found. This requires GNOME.${RC}"
        return 1
    fi

    if [ ! -f "$DOTFILES_DIR/scripts/gnome/restore-gnome-shortcuts.sh" ]; then
        printf "%b\n" "${RED}GNOME shortcuts restore script not found in dotfiles!${RC}"
        printf "%b\n" "${YELLOW}Please clone the dotfiles repository first.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}Restoring GNOME keyboard shortcuts...${RC}"
    cd "$DOTFILES_DIR"
    sh ./scripts/gnome/restore-gnome-shortcuts.sh
    
    printf "%b\n" "${GREEN}GNOME shortcuts restored successfully.${RC}"
}

restoreKdeShortcuts() {
    if ! command_exists kwriteconfig5 && ! command_exists kwriteconfig6; then
        printf "%b\n" "${RED}KDE configuration tools not found.${RC}"
        return 1
    fi

    printf "%b\n" "${YELLOW}KDE shortcuts restoration is available in the dotfiles.${RC}"
    printf "%b\n" "${CYAN}For KDE shortcuts, please use the full dotfiles installation.${RC}"
}

showMenu() {
    printf "%b\n" "${CYAN}=== Desktop Shortcuts Restore ===${RC}"
    
    if [ ! -d "$DOTFILES_DIR" ]; then
        printf "%b\n" "${RED}Dotfiles not found at $DOTFILES_DIR${RC}"
        printf "%b\n" "${YELLOW}Please clone the dotfiles repository first using 'TL40 Dotfiles Restore'${RC}"
        exit 1
    fi

    printf "%b\n" "1) Restore GNOME shortcuts"
    printf "%b\n" "2) Restore KDE shortcuts"
    printf "%b\n" "3) Auto-detect and restore"
    printf "%b\n" "4) Exit"
    printf "%b" "${GREEN}Enter your choice [1-4]: ${RC}"
    read -r choice
    
    case "$choice" in
        1)
            restoreGnomeShortcuts
            ;;
        2)
            restoreKdeShortcuts
            ;;
        3)
            if echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
                restoreGnomeShortcuts
            elif echo "$XDG_CURRENT_DESKTOP" | grep -qi "kde"; then
                restoreKdeShortcuts
            else
                printf "%b\n" "${YELLOW}Could not auto-detect desktop environment.${RC}"
                printf "%b\n" "${CYAN}Please select manually from the menu.${RC}"
            fi
            ;;
        4)
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice!${RC}"
            exit 1
            ;;
    esac
}

checkEnv
detectDesktop
showMenu
