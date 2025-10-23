#!/bin/sh -e

. ../../common-script.sh

installCursor() {
    if ! command_exists cursor; then
        printf "%b\n" "${YELLOW}Installing Cursor...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                TEMP_DEB="cursor.deb"

                curl -sSLo "$TEMP_DEB" 'https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest'

                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$TEMP_DEB"
                rm "$TEMP_DEB"
                
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm cursor-bin
                ;;
            dnf)
                TEMP_RPM="cursor.rpm"
                curl -sSLo "$TEMP_RPM" "https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest"

                "$ESCALATION_TOOL" "$PACKAGER" install -y "$TEMP_RPM"
                rm "$TEMP_RPM"
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
        printf "%b\n" "${GREEN}Cursor installed successfully.${RC}"
    else
        printf "%b\n" "${GREEN}Cursor is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installCursor
