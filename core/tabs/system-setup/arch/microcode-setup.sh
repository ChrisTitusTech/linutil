#!/bin/sh -e

. ../../common-script.sh

installMicrocode() {
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        printf "%b\n" "${CYAN}Intel CPU detected. Installing intel-ucode...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm intel-ucode
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        printf "%b\n" "${CYAN}AMD CPU detected. Installing amd-ucode...${RC}"
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm amd-ucode
    else
        printf "%b\n" "${YELLOW}Unable to determine CPU vendor. Skipping.${RC}"
        exit 0
    fi

    if command_exists mkinitcpio; then
        printf "%b\n" "${CYAN}Regenerating initramfs...${RC}"
        "$ESCALATION_TOOL" mkinitcpio -P
    fi

    printf "%b\n" "${GREEN}Microcode installed. Reboot to apply.${RC}"
}

checkEnv
checkEscalationTool
installMicrocode
