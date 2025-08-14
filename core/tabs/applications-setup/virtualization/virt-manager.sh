#!/bin/sh -e

. ../../common-script.sh

installVirtManager() {
    printf "%b\n" "${YELLOW}Installing Virtual Manager...${RC}"
    case "$PACKAGER" in
        apt-get|nala|zypper)
        	if ! command_exists virt-manager; then
		        "$ESCALATION_TOOL" "$PACKAGER" install -y virt-manager
		    else
		        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
		    fi
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y @virtualization 

            #sets the libvirtd service to start on system start
			sudo systemctl enable libvirtd
            sudo systemctl start libvirtd

			#add current user to virt manager group
			sudo usermod -a -G libvirt $(who | awk 'NR==1{print $1}')
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

    "$ESCALATION_TOOL" systemctl status qemu-kvm.service
}

checkEnv
checkEscalationTool
installVirtManager