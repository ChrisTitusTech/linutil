#!/bin/sh -e

. ../common-script.sh

install_virt_dependencies(){
    printf "${YELLOW}Installing Virt packages...${RC}\n"

    case $(command -v apt-get || command -v zypper || command -v dnf || command -v pacman) in
    *apt-get)
        ${ESCALATION_TOOL} apt-get update

        # Install Virt packages on Debian
        if (lsb_release -i  | grep -qi Debian); then
            ${ESCALATION_TOOL} apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system virtinst virt-manager bridge-utils dnsmasq

        # Install Virt packages on Ubuntu
        else
            ${ESCALATION_TOOL} apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager dnsmasq
        fi
        ;;

    *zypper)
        ${ESCALATION_TOOL} zypper update
        ${ESCALATION_TOOL} zypper install --non-interactive qemu-kvm libvirt virt-manager bridge-utils virt-install
        ;;

    *dnf)
        ${ESCALATION_TOOL} dnf update
        ${ESCALATION_TOOL} dnf install -y qemu-kvm virt-manager libvirt libvirt-daemon libvirt-daemon-driver-qemu bridge-utils virt-install virt-viewer dnsmasq
        ;;

    *pacman)
        ${ESCALATION_TOOL} pacman -Syu
        ${ESCALATION_TOOL} pacman -S --needed --noconfirm qemu virt-manager libvirt edk2-ovmf dnsmasq vde2 bridge-utils openbsd-netcat
        ;;    
    esac
}

enable_services(){
    read -p "Do you want to enable Virt Services? (y/n): " answer
    case $answer in
        y|Y)
            printf "${YELLOW}Enabling Virt Services${RC}\n"
            ${ESCALATION_TOOL} systemctl enable --now libvirtd
            ${ESCALATION_TOOL} systemctl enable --now libvirtd.socket
            ${ESCALATION_TOOL} systemctl enable --now virtlogd
            ;;
        n|N)
            printf "${YELLOW}Skipping Virt Services enablement${RC}\n"
            ;;
        *)
            printf "${RED}Invalid input. Please enter y or n.${RC}\n"
            enable_services
            ;;
    esac
}

add_user_to_libvirt_group(){
    read -p "Do you want to add $USER to the libvirt group? (y/n): " answer
    case $answer in
        y|Y)
            printf "${YELLOW}Adding $USER to libvirt group${RC}\n"
            ${ESCALATION_TOOL} usermod -aG libvirt $USER
            ;;
        n|N)
            printf "${YELLOW}Skipping adding $USER to libvirt group${RC}\n"
            ;;
        *)
            printf "${RED}Invalid input. Please enter y or n.${RC}\n"
            add_user_to_libvirt_group
            ;;
    esac
    printf "${YELLOW}Done!${RC}\n"

}

checkEscalationTool
install_virt_dependencies
enable_services
add_user_to_libvirt_group