#!/bin/sh -e

. ../common-script.sh

installGhostty() {
    if ! command_exists ghostty; then
    printf "%b\n" "${YELLOW}Installing Ghostty...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ghostty
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add ghostty
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy ghostty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Ghostty is already installed.${RC}"
    fi
}

setupGhosttyConfig() {
    printf "%b\n" "${YELLOW}Copying ghostty config files...${RC}"
    if [ -d "${HOME}/.config/ghostty" ] && [ ! -d "${HOME}/.config/ghostty-bak" ]; then
        cp -r "${HOME}/.config/ghostty" "${HOME}/.config/ghostty-bak"
    fi
    mkdir -p "${HOME}/.config/ghostty/"
    curl -sSLo "${HOME}/.config/ghostty/config" "https://raw.githubusercontent.com/ChrisTitusTech/dwm-titus/main/config/ghostty/config"
    printf "%b\n" "${GREEN}Ghostty configuration files copied.${RC}"
}

checkEnv
checkEscalationTool
installGhostty
setupGhosttyConfig
