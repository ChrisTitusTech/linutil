#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="org.jitsi.jitsi-meet"
APP_UNINSTALL_PKGS="jitsi jitsi-meet"


installJitsi() {
    if ! flatpak_app_installed org.jitsi.jitsi-meet && ! command_exists jitsi-meet; then
        printf "%b\n" "${YELLOW}Installing Jitsi meet...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl https://download.jitsi.org/jitsi-key.gpg.key | "$ESCALATION_TOOL" gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg
                printf "%b\n" 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" -y install jitsi-meet
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install jitsi
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm jitsi-meet-bin
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y jitsi-meet
                ;;
            apk)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}Unsupported package manager: ""$PACKAGER"". Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists jitsi-meet; then
            return 0
        fi
        if try_flatpak_install org.jitsi.jitsi-meet; then
            return 0
        fi
    else
        printf "%b\n" "${GREEN}Jitsi meet is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installJitsi
