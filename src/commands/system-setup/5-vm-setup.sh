#!/bin/sh -e

. ../common-script.sh

install_virt_dependencies(){
    printf "${YELLOW}Installing Virt packages...${RC}\n"

    case $(command -v apt-get || command -v zypper || command -v dnf || command -v pacman) in
    *apt-get)
        sudo apt-get update

        # Install Virt packages on Debian
        if (lsb_release -i  | grep -qi Debian); then
            sudo apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system virtinst virt-manager bridge-utils dnsmasq

        # Install Virt packages on Ubuntu
        else
            sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager dnsmasq
        fi
        ;;

    *zypper)
        sudo zypper update
        sudo zypper install --non-interactive qemu-kvm libvirt virt-manager bridge-utils virt-install
        ;;

    *dnf)
        sudo dnf update
        sudo dnf install -y qemu-kvm virt-manager libvirt libvirt-daemon libvirt-daemon-driver-qemu bridge-utils virt-install virt-viewer dnsmasq
        ;;

    *pacman)
        sudo pacman -Syu
        sudo pacman -S --needed --noconfirm qemu virt-manager libvirt edk2-ovmf dnsmasq vde2 bridge-utils openbsd-netcat
        ;;    
    esac
}

enable_services(){
    printf "${YELLOW}Enabling Virt Services${RC}\n"
    sudo systemctl enable --now libvirtd
    sudo systemctl enable --now virtlogd
}

add_user_to_libvirt_group(){
    printf "${YELLOW}Adding $USER to libvirt group${RC}\n"
    sudo usermod -aG libvirt $USER
    printf "${YELLOW}Done!${RC}\n"
}

checkEscalationTool
install_virt_dependencies
enable_services
add_user_to_libvirt_group