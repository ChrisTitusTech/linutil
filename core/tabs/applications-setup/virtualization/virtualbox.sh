#!/bin/sh 

. ../../common-script.sh

installVirtualBox() {
    printf "%b\n" "${YELLOW}Installing VirtualBox...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
        	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
    		"$ESCALATION_TOOL" printf "Types: deb\nURIs: http://download.virtualbox.org/virtualbox/debian\nSuites: ""$(lsb_release -cs 2>/dev/null)""\nComponents: contrib\nArchitectures: ""${ARCH}""\nSigned-By: /usr/share/keyrings/oracle-virtualbox-2016.gpg\n" > /etc/apt/sources.list.d/virtualbox.sources
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" -y install virtualbox-7.2

            vboxVersion=$(vboxmanage --version | cut -f1 -d"r")
            wget -c -O /home/"$USER"/Downloads/vbox.vbox-extpack https://download.virtualbox.org/virtualbox/"${vboxVersion}"/Oracle_VirtualBox_Extension_Pack-"${vboxVersion}".vbox-extpack
            VBoxManage extpack install vbox.vbox-extpack
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core
            dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
            if [ "$dnf_version" -eq 4 ]; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
            else
                "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install VirtualBox-7.2."${ARCH}"
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
            if command_exists yay || command_exists paru; then
                "$AUR_HELPER" -S --needed --noconfirm virtualbox-bin
            else
            	"$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm virtualbox-host-modules-arch
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm virtualbox
            fi
            "$ESCALATION_TOOL" modprobe vboxdrv
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

virtualBoxPermissions() {
    printf "%b\n" "${YELLOW}Adding current user to the vboxusers group...${RC}"
    "$ESCALATION_TOOL" usermod -aG "vboxusers" "$(who | awk 'NR==1{print $1}')"
}

getLatestVersion() {
    version=$(wget "https://raw.githubusercontent.com/VirtualBox/virtualbox/refs/heads/main/Version.kmk" -q -O - | sed '/^#/d' | cut -d'=' -f2 | cut -d'$' -f1 | xargs | sed 's/ /./g' | cut -c -3)
}

checkVirtualBox() {
    if ! command_exists virtualbox; then
        installVirtualBox
    else
        currentVersion=$(vboxmanage --version | cut -d'r' -f1)
        getLatestVersion

        if [ "${currentVersion%.*}" = "$version" ]; then
            printf "%b\n" "Latest version of VirtualBox already installed"
        else
            installVirtualBox
        fi
    fi
}

checkEnv
checkEscalationTool
checkVirtualBox
virtualBoxPermissions