#!/bin/sh -e

. ../../common-script.sh

installChrome() {
    if ! command_exists google-chrome; then
        printf "%b\n" "${YELLOW}Installing Google Chrome...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./google-chrome-stable_current_amd64.deb
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install google-chrome-stable
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm google-chrome
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fedora-workstation-repositories
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled google-chrome
                "$ESCALATION_TOOL" "$PACKAGER" install -y google-chrome-stable
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installChrome