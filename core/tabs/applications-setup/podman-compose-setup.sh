#!/bin/sh -e

. ../common-script.sh

install_podman_compose() {
    printf "%b\n" "${YELLOW}Installing Podman Compose...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y podman-compose
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install podman-compose
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman-compose
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y podman-compose
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

install_components() {
    if ! command_exists podman-compose || ! command_exists podman compose version; then
        install_podman_compose
    else
        printf "%b\n" "${GREEN}Podman Compose is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
install_components
