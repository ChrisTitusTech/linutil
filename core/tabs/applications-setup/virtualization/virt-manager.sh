#!/bin/sh -e

. ../../common-script.sh

installVirtManager() {
    printf "%b\n" "${YELLOW}Installing Virt-Manager...${RC}"
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
                "$ESCALATION_TOOL" flatpak install --noninteractive org.virt_manager.virt-manager
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
    fi

    "$ESCALATION_TOOL" systemctl status qemu-kvm.service
}

uninstallVirtManager() {
    printf "%b\n" "${YELLOW}Uninstalling Virt-Manager...${RC}"
    if command_exists virt-manager; then
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y virt-manager*
                ;;
            pacman)
                if command_exists yay || command_exists paru; then
                    "$AUR_HELPER" -R --noconfirm virt-manager
                else
                    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm virt-manager
                fi
                ;;
            *)
                "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.virt_manager.virt-manager
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Virt-Manager is not installed.${RC}"
    fi
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

main() {
    printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Virt-Manager${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) checkVirtManager ;;
        2) uninstallVirtManager ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main