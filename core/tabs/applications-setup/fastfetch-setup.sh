#!/bin/sh -e

. ../common-script.sh

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
                ;;
            apt-get|nala)
                curl -sSLo /tmp/fastfetch.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
                rm /tmp/fastfetch.deb
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
    fi
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ]; then
        if [ -d "${HOME}/.config/fastfetch-linutilbak" ]; then
            rm -rf  "${HOME}/.config/fastfetch-linutilbak"
        fi
        mv "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-linutilbak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}

checkEnv
checkEscalationTool
installFastfetch
setupFastfetchConfig