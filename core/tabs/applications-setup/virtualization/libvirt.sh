#!/bin/sh -e

. ../../common-script.sh

checkKVM() {
    if [ ! -e "/dev/kvm" ]; then
        printf "%b\n" "${RED}KVM is not available. Make sure you have CPU virtualization support enabled in your BIOS/UEFI settings. Please refer https://wiki.archlinux.org/title/KVM for more information.${RC}"
    else
        "$ESCALATION_TOOL" usermod "$USER" -aG kvm
    fi
}

# currently only for Arch. Need to test on other distros later
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
	printf "%b\n" "${YELLOW}Installing libvirt.${RC}"
    if ! command_exists libvirtd; then
        case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libvirt-daemon libvirt0
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libvirt libvirt-daemon libvirt0
            ;;
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm libvirt dmidecode
            setupLibvirt
		    ;;
		*)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Libvirt is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installLibvirt