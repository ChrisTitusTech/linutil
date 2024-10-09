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

check_python_pip() {
    if ! command_exists python3; then
        printf "%b\n" "${YELLOW}Pip not found. Installing pip...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install python3
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm python
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    fi

    if ! command_exists pip3; then
        printf "%b\n" "${YELLOW}Pip not found. Installing pip...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3-pip
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y python3-pip
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install python3-pip
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm python-pip
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    fi
}

install_podman_compose() {
    printf "%b\n" "${YELLOW}Installing Podman Compose...${RC}"
    case "$PACKAGER" in
        apt-get|nala|zypper|pacman)
            pip3 install --user podman-compose
            export PATH="$HOME/.local/bin:$PATH"
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
        check_python_pip
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
