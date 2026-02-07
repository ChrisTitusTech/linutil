#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.signal.Signal"
APP_UNINSTALL_PKGS="signal-desktop"


installSignal() {
    if ! flatpak_app_installed org.signal.Signal && ! command_exists signal; then
        printf "%b\n" "${YELLOW}Installing Signal...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
                "$ESCALATION_TOOL" tee /usr/share/keyrings/signal-desktop-keyring.gpg < signal-desktop-keyring.gpg > /dev/null
                printf "%b\n" 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/signal-xenial.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" -y install signal-desktop
                ;;
            zypper|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y signal-desktop
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm signal-desktop
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy Signal-Desktop
                ;;   
            dnf|apk)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}Unsupported package manager: ""$PACKAGER"". Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists signal; then
            return 0
        fi
        if try_flatpak_install org.signal.Signal; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Signal is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installSignal
