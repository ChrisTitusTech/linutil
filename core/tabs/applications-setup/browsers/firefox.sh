#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID=""
APP_UNINSTALL_PKGS="MozillaFirefox firefox firefox-esr"


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
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installFirefox
