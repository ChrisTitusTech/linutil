#!/bin/sh -e

. ../../common-script.sh

installFreeOffice() {  
    if ! command_exists softmaker-freeoffice-2024 freeoffice softmaker; then
        printf "%b\n" "${YELLOW}Installing Free Office...${RC}"
        case "$PACKAGER" in
        apt-get|nala)
            curl -O https://www.softmaker.net/down/softmaker-freeoffice-2024_1218-01_amd64.deb
            "$ESCALATION_TOOL" "$PACKAGER" install -y ./softmaker-freeoffice-2024_1218-01_amd64.deb
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://shop.softmaker.com/repo/rpm SoftMaker
            "$ESCALATION_TOOL" "$PACKAGER" --gpg-auto-import-keys refresh
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install softmaker-freeoffice-2024
            ;;
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm freeoffice
            ;;
        dnf)
            "$ESCALATION_TOOL" curl -O -qO /etc/yum.repos.d/softmaker.repo https://shop.softmaker.com/repo/softmaker.repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y softmaker-freeoffice-2024
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Free Office is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installFreeOffice