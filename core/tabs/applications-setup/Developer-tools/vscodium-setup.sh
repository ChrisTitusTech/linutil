#!/bin/sh -e

. ../../common-script.sh

installVsCodium() {
    if ! command_exists codium; then
        printf "%b\n" "${YELLOW}Installing VS Codium...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | elevated_execution dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
                echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | elevated_execution tee /etc/apt/sources.list.d/vscodium.list
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" install -y codium
                ;;
            zypper)
                elevated_execution rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
                printf "%b\n" "[gitlab.com_paulcarroty_vscodium_repo]\nname=gitlab.com_paulcarroty_vscodium_repo\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | elevated_execution tee -a /etc/zypp/repos.d/vscodium.repo
                elevated_execution "$PACKAGER" refresh
                elevated_execution "$PACKAGER" --non-interactive install codium
                ;;
            pacman)
                "$AUR_HELPER" -S --noconfirm vscodium-bin
                ;;
            dnf)
                elevated_execution rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
                printf "%b\n" "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | elevated_execution tee -a /etc/yum.repos.d/vscodium.repo
                elevated_execution "$PACKAGER" install -y codium
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}VS Codium is already installed.${RC}"
    fi

}

checkEnv
checkEscalationTool
checkAURHelper
installVsCodium
