#!/bin/sh -e

. ../../common-script.sh

installFirefox() {
    if ! command_exists firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                if [ "$DTYPE" != "ubuntu" ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y firefox-esr
                fi
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install MozillaFirefox
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm firefox
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" -y install firefox
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy firefox
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add firefox
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive org.mozilla.firefox
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
installFirefox
