#!/bin/sh -e

. ../../common-script.sh

installLibreWolf() {
    if ! flatpak_app_installed io.gitlab.librewolf-community && ! command_exists librewolf; then
        printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
        if try_flatpak_install io.gitlab.librewolf-community; then
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y extrepo
                "$ESCALATION_TOOL" extrepo enable librewolf
                "$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y librewolf
                ;;
            dnf)
                curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" install -y librewolf
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm --import https://rpm.librewolf.net/pubkey.gpg
                "$ESCALATION_TOOL" zypper ar -ef https://rpm.librewolf.net librewolf
                "$ESCALATION_TOOL" zypper refresh
                "$ESCALATION_TOOL" zypper --non-interactive install librewolf
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm librewolf-bin
                ;;
            xbps-install)
                printf '%s\n' 'repository=https://github.com/index-0/librewolf-void/releases/latest/download/' | "$ESCALATION_TOOL" tee /etc/xbps.d/20-librewolf.conf > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" -Syu librewolf
                ;;
            apk)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}LibreWolf Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installLibreWolf
