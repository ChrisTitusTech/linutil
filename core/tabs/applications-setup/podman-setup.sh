#!/bin/sh -e

. ../common-script.sh

choose_installation() { 
    clear
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}Podman${RC}"
    printf "%b\n" "2. ${YELLOW}Podman Compose${RC}"
    printf "%b\n" "3. ${YELLOW}Both${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE

    case "$CHOICE" in
        1) INSTALL_PODMAN=1; INSTALL_COMPOSE=0 ;;
        2) INSTALL_PODMAN=0; INSTALL_COMPOSE=1 ;;
        3) INSTALL_PODMAN=1; INSTALL_COMPOSE=1 ;;
        *) printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"; exit 1 ;;
    esac
}

install_podman() {
    printf "%b\n" "${YELLOW}Installing Podman...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y podman
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install podman
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm podman
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y podman
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

install_podman_compose() {
    printf "%b\n" "${YELLOW}Installing Podman Compose...${RC}"
    case "$PACKAGER" in
        apt-get|nala|zypper|pacman)
            "$ESCALATION_TOOL" pip3 install podman-compose
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
    choose_installation 

    if [ "$INSTALL_PODMAN" -eq 1 ]; then
        if ! command_exists podman; then
            install_podman
        else
            printf "%b\n" "${GREEN}Podman is already installed.${RC}"
        fi
    fi

    if [ "$INSTALL_COMPOSE" -eq 1 ]; then
        if ! command_exists podman-compose; then
            install_podman_compose
        else
            printf "%b\n" "${GREEN}Podman Compose is already installed.${RC}"
        fi
    fi
}

checkEnv
checkEscalationTool
install_components
