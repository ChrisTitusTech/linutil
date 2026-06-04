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
                cd "$TMP_BUILD_DIR"
                git clone https://aur.archlinux.org/yay-bin.git
                cd yay-bin && makepkg --noconfirm -si

                cd - >/dev/null
                rm -rf "$TMP_BUILD_DIR"
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
