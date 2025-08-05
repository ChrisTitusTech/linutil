#!/bin/sh -e

. ../../common-script.sh

installQEMUDesktop() {
    printf "%b\n" "${YELLOW}Installing QEMU.${RC}"
    case "$PACKAGER" in
        apt-get|nala)
        	if ! command_exists qemu-img; then
		        "$ESCALATION_TOOL" "$PACKAGER" install -y qemu-utils qemu-system-x86 qemu-system-gui
		    else
		        printf "%b\n" "${GREEN}QEMU already installed.${RC}"
		    fi
            ;;
        zypper)
            if ! command_exists qemu-img; then
                "$ESCALATION_TOOL" "$PACKAGER" install -y qemu
            else
                printf "%b\n" "${GREEN}QEMU already installed.${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            "$ESCALATION_TOOL" flatpak install --noninteractive org.virt_manager.virt_manager.Extension.Qemu
            ;;
    esac
}

checkEnv
checkEscalationTool
installQEMUDesktop