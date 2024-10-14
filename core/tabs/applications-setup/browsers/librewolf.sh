#!/bin/sh -e

. ../../common-script.sh

installLibreWolf() {
    if ! command_exists librewolf; then
        printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                elevated_execution "$PACKAGER" install -y gnupg lsb-release apt-transport-https ca-certificates
                distro=`if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi`
                curl -fsSL https://deb.librewolf.net/keyring.gpg | elevated_execution gpg --dearmor -o /usr/share/keyrings/librewolf.gpg
                echo "Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg" | elevated_execution tee /etc/apt/sources.list.d/librewolf.sources > /dev/null
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" install -y librewolf
                ;;
            dnf)
                curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo > /dev/null
                elevated_execution "$PACKAGER" install -y librewolf
                ;;
            zypper)
                elevated_execution rpm --import https://rpm.librewolf.net/pubkey.gpg
                elevated_execution zypper ar -ef https://rpm.librewolf.net librewolf
                elevated_execution zypper refresh
                elevated_execution zypper --non-interactive install librewolf
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm librewolf-bin
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