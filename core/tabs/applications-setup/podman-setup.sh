#!/bin/sh -e

. ../common-script.sh

installPodman() {
    if ! command_exists podman; then
        printf "%b\n" "${YELLOW}Installing Podman...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add podman
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy podman
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Podman is already installed.${RC}"
    fi
}

installPodmanCompose() {
    if ! command_exists podman-compose; then
        printf "%b\n" "${YELLOW}Installing Podman Compose...${RC}"
        case "$PACKAGER" in
            apt-get|nala|zypper|dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman-compose
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman-compose
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add podman-compose
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy podman-compose
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Podman Compose is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPodman
installPodmanCompose

printf "%b\n" "${GREEN}Podman and Podman Compose installation complete.${RC}"