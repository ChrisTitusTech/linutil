#!/bin/sh -e

. ../common-script.sh

installPipewirePkgs() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber lib32-pipewire
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y pipewire pipewire-pulse wireplumber pipewire-audio-client-libraries 2>/dev/null || \
            "$ESCALATION_TOOL" "$PACKAGER" install -y pipewire pipewire-pulse wireplumber
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y pipewire pipewire-pulse wireplumber pipewire-jack-audio-connection-kit
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install pipewire pipewire-pulse wireplumber pipewire-jack
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add pipewire pipewire-pulse wireplumber
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy pipewire pipewire-pulse wireplumber
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y pipewire wireplumber
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER. Install pipewire and wireplumber manually.${RC}"
            exit 1
            ;;
    esac
}

installPipewire() {
    installPipewirePkgs

    if command_exists systemctl; then
        "$ESCALATION_TOOL" systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
        printf "%b\n" "${GREEN}PipeWire services enabled.${RC}"
    fi

    printf "%b\n" "${GREEN}PipeWire with WirePlumber installed. Reboot or relogin to apply.${RC}"
}

checkEnv
installPipewire
