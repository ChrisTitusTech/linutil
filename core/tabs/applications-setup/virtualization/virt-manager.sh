#!/bin/sh -e

. ../../common-script.sh

installVirtManager() {
    printf "%b\n" "${YELLOW}Installing Virtual Manager...${RC}"
    if ! command_exists virt-manager; then
        case "$PACKAGER" in
            apt-get|nala|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y virt-manager
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y @virtualization 

                #sets the libvirtd service to start on system start
    			sudo systemctl enable libvirtd
                sudo systemctl start libvirtd

    			#add current user to virt manager group
    			sudo usermod -a -G "libvirt" "$(who | awk 'NR==1{print $1}')"
                ;;
            pacman)
                if command_exists yay || command_exists paru; then
                    "$AUR_HELPER" -S --needed --noconfirm virt-manager
                else         	
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm virt-manager
                fi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                "$ESCALATION_TOOL" flatpak install --noninteractive org.virt_manager.virt-manager
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
    fi

    "$ESCALATION_TOOL" systemctl status qemu-kvm.service
}

getLatestVersion() {
    version=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/virt-manager/virt-manager | grep -v 'latest' | tail -n1 | cut -d '/' --fields=3 | cut -d '^' -f1 | cut -d 'v' -f2)
}

checkVirtManager() {
    if ! command_exists virt-manager; then
        installVirtManager
    else
        installedVersion=$(virt-manager --version)
        if [ "$version" = "$installedVersion" ]; then
            printf "%b\n" "Latest Version of virt-manager already installed"
        else
            installVirtManager
        fi
    fi
}

checkEnv
checkEscalationTool
installVirtManager