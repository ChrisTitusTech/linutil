#!/bin/sh 

. ../../common-script.sh

installVirtualBox() {
    printf "%b\n" "${YELLOW}Installing VirtualBox...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
        	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
        	"$ESCALATION_TOOL" sh -c 'echo "Types: deb\nURIs: http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs)\nSuites: $(lsb_release -cs 2>/dev/null)\nComponents: contrib\nArchitectures: $ARCH\nSigned-By: /usr/share/keyrings/oracle-virtualbox-2016.gpg\n" > /etc/apt/sources.list.d/virtualbox.sources'
    		"$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" -y install virtualbox-7.1

            wget -P /home/$USER/Downloads/vbox.vbox-extpack https://download.virtualbox.org/virtualbox/$(vboxmanage --version | cut -f1 -d"r")/Oracle_VirtualBox_Extension_Pack-$(vboxmanage --version | cut -f1 -d"r").vbox-extpack
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
            "$ESCALATION_TOOL" "$PACKAGER" -y install VirtualBox-7.1.$ARCH
            "$ESCALATION_TOOL" "$PACKAGER" -y install virtualbox-guest-additions.$ARCH
            ;;
        zypper)
            if [ "$DTYPE" == "opensuse-leap" ]; then 
        	    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc
                sudo rpm --import oracle_vbox_2016.asc
               "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://download.virtualbox.org/virtualbox/rpm/opensuse/virtualbox.repo
            fi
            "$ESCALATION_TOOL" "$PACKAGER" install -y virtualbox
            "$ESCALATION_TOOL" "$PACKAGER" install -y virtualbox-guest-tools
            ;;
        pacman)
        	"$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm virtualbox-host-modules-arch
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm virtualbox 
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
    "$ESCALATION_TOOL" usermod -aG vboxusers "$USER"
}

checkEnv
checkEscalationTool
installVirtualBox
virtualBoxPermissions