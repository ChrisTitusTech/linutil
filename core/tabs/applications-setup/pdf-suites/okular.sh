#!/bin/sh -e

. ../../common-script.sh

installOkular() {
    if ! command_exists okular; then
        printf "%b\n" "${YELLOW}Installing Okular...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm okular
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add okular
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy okular
                ;;
            apt-get|nala|zypper|dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y okular
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak --noninteractive org.kde.okular
                ::
        esac
    else
        printf "%b\n" "${GREEN}Okular is already installed.${RC}"
    fi
}

checkEnv
installOkular
