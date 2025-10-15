#!/bin/sh -e

. ../../common-script.sh

installCursor() {
    if ! command_exists cursor; then
        printf "%b\n" "${YELLOW}Installing Cursor...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                TEMP_DEB="$(mktemp)"
                wget -O "$TEMP_DEB" "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest"

                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y $TEMP_DEB
                "$ESCALATION_TOOL" rm $TEMP_DEB # Removes temp deb file
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm cursor-bin
                ;;
            dnf)
                TEMP_RPM="$(mktemp)"
                wget -O "$TEMP_RPM" "https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest"

                "$ESCALATION_TOOL" "$PACKAGER" install -y $TEMP_RPM
                "$ESCALATION_TOOL" rm $TEMP_RPM # Removes temp rpm file
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Cursor desktop is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installCursor