#!/bin/sh -e

. ../../common-script.sh

setUpRepos() {
    if ! grep -q "^\s*\[jupiter-staging\]" /etc/pacman.conf; then
        printf "%b\n" "${CYAN}Adding jupiter-staging to pacman repositories...${RC}"
        echo "[jupiter-staging]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
        echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
        echo "SigLevel = Never" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
    fi
    if ! grep -q "^\s*\[holo-staging\]" /etc/pacman.conf; then
        printf "%b\n" "${CYAN}Adding holo-staging to pacman repositories...${RC}"
        echo "[holo-staging]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
        echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
        echo "SigLevel = Never" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
    fi
}

installKernel() {
    if ! "$PACKAGER" -Q | grep -q "\blinux-neptune"; then
        printf "%b\n" "${CYAN}Installing linux-neptune..."
        "$ESCALATION_TOOL" "$PACKAGER" -Syyu --noconfirm
        "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm linux-neptune linux-neptune-headers steamdeck-dsp jupiter-staging/alsa-ucm-conf
        "$ESCALATION_TOOL" mkinitcpio -P
    else
        printf "%b\n" "${GREEN}linux-neptune detected. Skipping installation.${RC}"
    fi

    if [ -f /etc/default/grub ]; then
        printf "%b\n" "${CYAN}Updating GRUB...${RC}"
    if ! grep -q '^UPDATEDEFAULT=' /etc/default/grub; then
        echo 'UPDATEDEFAULT=yes' | "$ESCALATION_TOOL" tee -a /etc/default/grub
    else
        "$ESCALATION_TOOL" sed -i 's/^UPDATEDEFAULT=.*/UPDATEDEFAULT=yes/' /etc/default/grub
    fi
    if [ -f /boot/grub/grub.cfg ]; then
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "${RED}GRUB configuration file not found. Run grub-mkconfig manually.${RC}"
    fi
    else
        printf "%b\n" "${RED}GRUB not detected. Manually set your bootloader to use linux-neptune.${RC}"
    fi
}

copyFirmwareFiles() {
    printf "%b\n" "${CYAN}Copying firmware files...${RC}"
    "$ESCALATION_TOOL" mkdir -p /usr/lib/firmware/cirrus
    "$ESCALATION_TOOL" cp /usr/lib/firmware/cs35l41-dsp1-spk-cali.bin /usr/lib/firmware/cirrus/
    "$ESCALATION_TOOL" cp /usr/lib/firmware/cs35l41-dsp1-spk-cali.wmfw  /usr/lib/firmware/cirrus/
    "$ESCALATION_TOOL" cp /usr/lib/firmware/cs35l41-dsp1-spk-prot.bin  /usr/lib/firmware/cirrus/
    "$ESCALATION_TOOL" cp /usr/lib/firmware/cs35l41-dsp1-spk-prot.wmfw  /usr/lib/firmware/cirrus/
}

checkEnv
checkEscalationTool
setUpRepos
installKernel
copyFirmwareFiles
