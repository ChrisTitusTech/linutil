#!/bin/sh 

. ../../common-script.sh

installVirtualBox() {
    printf "%b\n" "${YELLOW}Installing VirtualBox...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y gnupg gnupg2
        	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | "$ESCALATION_TOOL" gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
    		printf "%b" "Types: deb\nURIs: http://download.virtualbox.org/virtualbox/debian\nSuites: ""$(lsb_release -cs 2>/dev/null)""\nComponents: contrib\nArchitectures: ""${ARCH}""\nSigned-By: /usr/share/keyrings/oracle-virtualbox-2016.gpg\n" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/virtualbox.sources
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y virtualbox-"${version}"

            
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core @virtualization 
            dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
            if [ "$dnf_version" -eq 4 ]; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
            else
                "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install VirtualBox-"${version}"."${ARCH}"
            "$ESCALATION_TOOL" "$PACKAGER" -y install virtualbox-guest-additions."${ARCH}"
            ;;
        zypper)
            if [ "$DTYPE" = "opensuse-leap" ]; then 
        	    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc
                sudo rpm --import oracle_vbox_2016.asc
               "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://download.virtualbox.org/virtualbox/rpm/opensuse/virtualbox.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" install -y virtualbox
            "$ESCALATION_TOOL" "$PACKAGER" install -y virtualbox-guest-tools
            ;;
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-utils virtualbox-guest-iso virtualbox-host-modules-lts

            vboxVersion=$(vboxmanage --version | awk 'NR==8{print}' | cut -f1 -d"r")
            wget -c -O /home/"$USER"/Downloads/Oracle_VirtualBox_Extension_Pack-"${vboxVersion}".vbox-extpack https://download.virtualbox.org/virtualbox/"${vboxVersion}"/Oracle_VirtualBox_Extension_Pack-"${vboxVersion}".vbox-extpack
            VBoxManage extpack install Oracle_VirtualBox_Extension_Pack-"${vboxVersion}".vbox-extpack
            sudo rm /home/"$USER"/Downloads/Oracle_VirtualBox_Extension_Pack-"${vboxVersion}".vbox-extpack
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
    sh libvirt.sh
}

uninstallVirtualBox() {
    printf "%b\n" "${YELLOW}Uninstalling VirtualBox...${RC}"
    if command_exists virtualbox; then
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y virtualbox*
                ;;
            pacman)
                "$AUR_HELPER" -R --noconfirm virtualbox-bin
                ;;
            *)
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}VirtualBox is not installed.${RC}"
    fi
}

virtualBoxPermissions() {
    printf "%b\n" "${YELLOW}Adding current user to the vboxusers group...${RC}"
    "$ESCALATION_TOOL" usermod -aG "vboxusers" "$(who | awk 'NR==1{print $1}')"
}

getLatestVersion() {
    version=$(wget "https://raw.githubusercontent.com/VirtualBox/virtualbox/refs/heads/main/Version.kmk" -q -O - | sed '/^#/d' | cut -d'=' -f2 | cut -d'$' -f1 | xargs | sed 's/ /./g' | cut -c -3)
}

checkVirtualBox() {
    getLatestVersion
    if ! command_exists virtualbox; then
        installVirtualBox
    else
        currentVersion=$(vboxmanage --version | cut -d'r' -f1)

        if [ "${currentVersion%.*}" -ge "$version" ]; then
            printf "%b\n" "Latest version of VirtualBox already installed"
        else
            installVirtualBox
        fi
    fi

    virtualBoxPermissions
}

main() {
    printf "%b\n" "${YELLOW}Do you want to Install or Uninstall VirtualBox${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) checkVirtualBox ;;
        2) uninstallVirtualBox ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
