#!/bin/sh -e

. ../../common-script.sh

installJitsi() {
    if ! command_exists org.jitsi.jitsi-meet && ! command_exists jitsi-meet; then
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
                checkFlatpak
                flatpak install flathub org.jitsi.jitsi-meet
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Jitsi meet is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installJitsi