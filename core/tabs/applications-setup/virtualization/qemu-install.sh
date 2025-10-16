#!/bin/sh -e

. ../../common-script.sh

installQEMUDesktop() {
    printf "%b\n" "${YELLOW}Installing QEMU.${RC}"
    if ! command_exists qemu-img; then
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y qemu-utils qemu-system-"$ARCH" qemu-system-gui
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y @virtualization 

                sudo systemctl start libvirtd
                #sets the libvirtd service to start on system start
                sudo systemctl enable libvirtd

                #add current user to virt manager group
                sudo usermod -a -G "libvirt" "$(who | awk 'NR==1{print $1}')"
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y qemu
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm qemu-desktop
                checkKVM
                installQEMUEmulators
                ;;
            *)
                if command_exists flatpak; then
                    "$ESCALATION_TOOL" flatpak install --noninteractive org.virt_manager.virt_manager.Extension.Qemu
                fi
                ;;
        esac
    else
        printf "%b\n" "${GREEN}QEMU already installed.${RC}"
    fi

    "$ESCALATION_TOOL" systemctl status qemu-kvm.service
}

installQEMUEmulators() {
    printf "%b\n" "${YELLOW}Installing QEMU.${RC}"
    case "$PACKAGER" in
        pacman)
            if ! "$PACKAGER" -Q | grep -q "qemu-emulators-full "; then
                printf "%b\n" "${YELLOW}Installing QEMU-Emulators.${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qemu-emulators-full swtpm
            else
                printf "%b\n" "${GREEN}QEMU-Emulators already installed.${RC}"
            fi
            ;;
        *)
            ;;
    esac
}

uninstallQEMU() {
    printf "%b\n" "${YELLOW}Uninstalling QEMU...${RC}"
    if command_exists qemu-img; then
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y qemu*
                ;;
            pacman)
                "$AUR_HELPER" -R --noconfirm qemu-desktop
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.virt_manager.virt_manager.Extension.Qemu
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}QEMU is not installed.${RC}"
    fi
}

checkKVM() {
    if [ ! -e "/dev/kvm" ]; then
        printf "%b\n" "${RED}KVM is not available. Make sure you have CPU virtualization support enabled in your BIOS/UEFI settings. Please refer https://wiki.archlinux.org/title/KVM for more information.${RC}"
    else
        "$ESCALATION_TOOL" usermod "$(who | awk 'NR==1{print $1}')" -aG kvm
    fi
}

main() {
    printf "%b\n" "${YELLOW}Do you want to Install or Uninstall QEMU Desktop${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installQEMUDesktop ;;
        2) uninstallQEMU ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main