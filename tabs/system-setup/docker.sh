#!/bin/sh -e

. ../common-script.sh

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
}

install_docker_ubuntu_debian() {
    printf "%b\n" "Installing Docker for Ubuntu/Debian..."
    $SUDO apt-get update
    $SUDO apt-get install -y ca-certificates curl
    $SUDO install -m 0755 -d /etc/apt/keyrings
    $SUDO curl -fsSL https://download.docker.com/linux/$OS/gpg -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS \
    $VERSION_CODENAME stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

    $SUDO apt-get update
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_fedora() {
    printf "%b\n" "Installing Docker for Fedora..."
    $SUDO dnf -y install dnf-plugins-core
    $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker() {
    detect_os
    printf "%b\n" "Detected OS: $OS $VERSION"

    case $OS in
        ubuntu|debian)
            install_docker_ubuntu_debian
            ;;
        fedora)
            install_docker_fedora
            ;;
        *)
            printf "%b\n" "Unsupported OS: $OS"
            return 1
            ;;
    esac

    # Start Docker service
    $SUDO systemctl start docker
    $SUDO systemctl enable docker

    # Add current user to docker group
    $SUDO usermod -aG docker "$USER"
    printf "%b\n" "Docker installed successfully. Please log out and back in for group changes to take effect."
}

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        printf "%b\n" "Docker is installed."
        docker --version
        printf "%b\n" "Docker service status:"
        $SUDO systemctl status docker
    else
        printf "%b\n" "Docker is not installed."
    fi
}

docker_info() {
    printf "%b\n" "Docker Information:"
    docker info
}

docker_images() {
    printf "%b\n" "Docker Images:"
    docker images
}

docker_containers() {
    printf "%b\n" "Docker Containers:"
    docker ps -a
}

menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}Docker Management${RC}"
        printf "%b\n" "=================="
        printf "1) Install Docker\n"
        printf "2) Check Docker installation\n"
        printf "3) Show Docker information\n"
        printf "4) List Docker images\n"
        printf "5) List Docker containers\n"
        printf "6) Exit\n"

        printf "%b" "${YELLOW}Enter your choice (1-6): ${RC}"
        read -r choice

        case $choice in
            1) install_docker ;;
            2) check_docker ;;
            3) docker_info ;;
            4) docker_images ;;
            5) docker_containers ;;
            6) printf "%b\n" "${GREEN}Exiting...${RC}"; exit 0 ;;
            *) printf "%b\n" "${RED}Invalid choice. Please try again.${RC}" ;;
        esac

        printf "%b\n" "${YELLOW}Press Enter to continue...${RC}"
        read -r dummy
    done
}

checkEnv
checkEscalationTool
menu
