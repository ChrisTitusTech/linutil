#!/bin/sh -e

. ../../common-script.sh

installPipewire() {
    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber lib32-pipewire

    if command_exists systemctl; then
        systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
        printf "%b\n" "${GREEN}PipeWire services enabled.${RC}"
    fi

    printf "%b\n" "${GREEN}PipeWire with WirePlumber installed. Reboot or relogin to apply.${RC}"
}

checkEnv
installPipewire
