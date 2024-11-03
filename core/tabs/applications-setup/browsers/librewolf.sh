#!/bin/sh -e

. ../../common-script.sh

installLibreWolf() {
    if ! command_exists io.gitlab.librewolf-community && ! command_exists librewolf; then
        printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gnupg lsb-release apt-transport-https ca-certificates
                distro=`if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi`
                curl -fsSL https://deb.librewolf.net/keyring.gpg | "$ESCALATION_TOOL" gpg --dearmor -o /usr/share/keyrings/librewolf.gpg
                echo "Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/librewolf.sources > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y librewolf
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
            apk)
                checkFlatpak
                flatpak install flathub io.gitlab.librewolf-community
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