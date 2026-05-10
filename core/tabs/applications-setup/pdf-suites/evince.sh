#!/bin/sh -e

. ../../common-script.sh

installEvince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm evince
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add evince
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy evince
                ;;
            apt-get|nala|zypper|dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y evince
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak --noninteractive org.gnome.Evince
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

checkEnv
installEvince