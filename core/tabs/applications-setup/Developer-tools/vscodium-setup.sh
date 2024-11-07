#!/bin/sh -e

. ../../common-script.sh

installVsCodium() {
    if ! command_exists com.vscodium.codium && ! command_exists codium; then
        printf "%b\n" "${YELLOW}Installing VS Codium...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | "$ESCALATION_TOOL" dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
                echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/vscodium.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y codium
                ;;
            zypper)
                "$ESCALATION_TOOL" rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
                printf "%b\n" "[gitlab.com_paulcarroty_vscodium_repo]\nname=gitlab.com_paulcarroty_vscodium_repo\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | "$ESCALATION_TOOL" tee -a /etc/zypp/repos.d/vscodium.repo
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install codium
                ;;
            pacman)
                "$AUR_HELPER" -S --noconfirm vscodium-bin
                ;;
            dnf)
                "$ESCALATION_TOOL" rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
                printf "%b\n" "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | "$ESCALATION_TOOL" tee -a /etc/yum.repos.d/vscodium.repo
                "$ESCALATION_TOOL" "$PACKAGER" install -y codium
                ;;
            apk)
                checkFlatpak
                flatpak install -y flathub com.vscodium.codium
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
