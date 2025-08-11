#!/bin/sh -e

. ../../common-script.sh

installVirtManager() {
    printf "%b\n" "${YELLOW}Installing VirtualBox...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
        	if ! command_exists virt-manager; then
		        "$ESCALATION_TOOL" "$PACKAGER" install -y virt-manager
		    else
		        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
		    fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y @virtualization 

            sudo systemctl start libvirtd
			#sets the libvirtd service to start on system start
			sudo systemctl enable libvirtd

			#add current user to virt manager group
			sudo usermod -a -G libvirt $(whoami)
            ;;
        zypper)
            if ! command_exists virt-manager; then
		        "$ESCALATION_TOOL" "$PACKAGER" install -y virt-manager
		    else
		        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
		    fi
            ;;
        pacman)
        	if ! command_exists virt-manager; then
		        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm virt-manager
		    else
		        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
		    fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            "$ESCALATION_TOOL" flatpak install --noninteractive org.virt_manager.virt-manager
            exit 1
            ;;
    esac
}

checkEnv
checkEscalationTool
installVirtManager