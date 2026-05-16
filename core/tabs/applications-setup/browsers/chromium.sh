#!/bin/sh -e

. ../../common-script.sh

installChromium() {
if ! command_exists chromium; then
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm chromium
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add chromium
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy chromium
            ;;
        apt-get|nala|zypper|dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y chromium
            ;;
        *)
            checkFlatpak
            "$ESCALATION_TOOL" flatpak install --noninteractive org.chromium.Chromium
            ;;
    esac
else
    printf "%b\n" "${GREEN}Chromium Browser is already installed.${RC}"
fi
}

checkEnv
installChromium