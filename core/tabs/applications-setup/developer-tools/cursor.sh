#!/bin/sh -e

. ../../common-script.sh

installCursor() {
    if ! command_exists cursor; then
        printf "%b\n" "${YELLOW}Installing Cursor...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                if apt-cache search "^${PACKAGE_NAME}$" | grep -q "^${PACKAGE_NAME} -"; then
                    TEMP_DEB="cursor.deb"

                    curl -sSLo "$TEMP_DEB" 'https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest'

                    "$ESCALATION_TOOL" "$PACKAGER" update
                    "$ESCALATION_TOOL" "$PACKAGER" install -y "$TEMP_DEB"
                    rm "$TEMP_DEB"
                else
                    "$ESCALATION_TOOL" "$PACKAGER" install -y cursor
                fi

                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm cursor-bin
                ;;
            dnf)
                if dnf list available "cursor" > /dev/null; then
                    "$ESCALATION_TOOL" "$PACKAGER" install -y cursor
                else
                    TEMP_RPM="cursor.rpm"
                    curl -sSLo "$TEMP_RPM" "https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest"

                    "$ESCALATION_TOOL" "$PACKAGER" install -y "$TEMP_RPM"
                    rm "$TEMP_RPM"
                fi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Cursor is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installCursor
