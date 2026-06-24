#!/bin/sh -e

. ../../common-script.sh

AUR_HELPER_CHECKED=true

installDepend() {
    case "$PACKAGER" in
        pacman)
            if ! command_exists yay; then
                printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel git
                TMP_BUILD_DIR=$(mktemp -d)
                trap 'rm -rf "$TMP_BUILD_DIR"' 0
                git clone https://aur.archlinux.org/yay-bin.git "$TMP_BUILD_DIR/yay-bin"
                (
                    cd "$TMP_BUILD_DIR/yay-bin"
                    makepkg --noconfirm -si
                )
                rm -rf "$TMP_BUILD_DIR"
                trap - 0
                printf "%b\n" "${GREEN}Yay installed${RC}"
            else
                printf "%b\n" "${GREEN}Aur helper already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installDepend
