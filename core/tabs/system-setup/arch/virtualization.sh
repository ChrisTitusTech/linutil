#!/bin/sh -e

. ../../common-script.sh

installQEMUDesktop() {
    if ! command_exists qemu-img; then
        printf "%b\n" "${YELLOW}Installing QEMU.${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qemu-desktop
    else
        printf "%b\n" "${GREEN}QEMU is already installed.${RC}"
    fi
    checkKVM
}

installQEMUEmulators() {
    if ! "$PACKAGER" -Q | grep -q "qemu-emulators-full "; then
        printf "%b\n" "${YELLOW}Installing QEMU-Emulators.${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qemu-emulators-full swtpm
    else
        printf "%b\n" "${GREEN}QEMU-Emulators already installed.${RC}"
    fi
}

installVirtManager() {
    if ! command_exists virt-manager; then
        printf "%b\n" "${YELLOW}Installing Virt-Manager.${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm virt-manager
    else
        printf "%b\n" "${GREEN}Virt-Manager already installed.${RC}"
    fi
}

checkKVM() {
    if [ ! -e "/dev/kvm" ]; then
        printf "%b\n" "${RED}KVM is not available. Make sure you have CPU virtualization support enabled in your BIOS/UEFI settings. Please refer https://wiki.archlinux.org/title/KVM for more information.${RC}"
    else
        "$ESCALATION_TOOL" usermod "$USER" -aG kvm
    fi
}

setupLibvirt() {
    printf "%b\n" "${YELLOW}Configuring Libvirt.${RC}"
    if "$PACKAGER" -Q | grep -q "iptables "; then
        "$ESCALATION_TOOL" "$PACKAGER" -Rdd --noconfirm iptables
    fi

    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm dnsmasq iptables-nft
    "$ESCALATION_TOOL" sed -i 's/^#\?firewall_backend\s*=\s*".*"/firewall_backend = "iptables"/' "/etc/libvirt/network.conf"

    if systemctl is-active --quiet polkit; then
        "$ESCALATION_TOOL" sed -i 's/^#\?auth_unix_ro\s*=\s*".*"/auth_unix_ro = "polkit"/' "/etc/libvirt/libvirtd.conf"
        "$ESCALATION_TOOL" sed -i 's/^#\?auth_unix_rw\s*=\s*".*"/auth_unix_rw = "polkit"/' "/etc/libvirt/libvirtd.conf"
    fi

    "$ESCALATION_TOOL" usermod "$USER" -aG libvirt

    for value in libvirt libvirt_guest; do
        if ! grep -wq "$value" /etc/nsswitch.conf; then
            "$ESCALATION_TOOL" sed -i "/^hosts:/ s/$/ ${value}/" /etc/nsswitch.conf
        fi
    done

    "$ESCALATION_TOOL" systemctl enable --now libvirtd.service
    "$ESCALATION_TOOL" virsh net-autostart default

    checkKVM
}

installLibvirt() {
    if ! command_exists libvirtd; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm libvirt dmidecode
    else
        printf "%b\n" "${GREEN}Libvirt is already installed.${RC}"
    fi
    setupLibvirt
}

main() {
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}QEMU${RC}"
    printf "%b\n" "2. ${YELLOW}QEMU-Emulators ( Extended architectures )${RC}"
    printf "%b\n" "3. ${YELLOW}Libvirt${RC}"
    printf "%b\n" "4. ${YELLOW}Virtual-Manager${RC}"
    printf "%b\n" "5. ${YELLOW}All${RC}"
    printf "%b" "Enter your choice [1-5]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installQEMUDesktop ;;
        2) installQEMUEmulators ;;
        3) installLibvirt ;;
        4) installVirtManager ;;
        5)
            installQEMUDesktop
            installQEMUEmulators
            installLibvirt
            installVirtManager
            ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
