#!/bin/sh -e

. ../common-script.sh

install_nvidia_container_toolkit() {
    clear
    printf "%b\n" "${YELLOW}Installing NVIDIA Container Toolkit...${RC}"

    case ${PACKAGER} in
        apt-get|nala)
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
            sudo apt-get update
            sudo apt-get install -y nvidia-container-toolkit
            ;;
        dnf|yum)
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            sudo yum install -y nvidia-container-toolkit
            ;;
        zypper)
            sudo zypper ar https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
            sudo zypper --gpg-auto-import-keys install -y nvidia-container-toolkit
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}NVIDIA Container Toolkit installed successfully.${RC}"
}

configure_runtime() {
    clear
    printf "%b\n" "${YELLOW}Select the container runtime to configure:${RC}"
    echo "1. Docker"
    echo "2. Containerd (for Kubernetes)"
    echo "3. CRI-O"
    echo "4. Exit"
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            sudo nvidia-ctk runtime configure --runtime=docker
            sudo systemctl restart docker
            ;;
        2)
            sudo nvidia-ctk runtime configure --runtime=containerd
            sudo systemctl restart containerd
            ;;
        3)
            sudo nvidia-ctk runtime configure --runtime=crio
            sudo systemctl restart crio
            ;;
        4)
            return
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
            ;;
    esac

    printf "%b\n" "${GREEN}Container runtime configured successfully.${RC}"
}

check_installation() {
    if command -v nvidia-container-toolkit >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}NVIDIA Container Toolkit is installed.${RC}"
    else
        printf "%b\n" "${RED}NVIDIA Container Toolkit is not installed.${RC}"
    fi
}

menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}NVIDIA Container Toolkit Management${RC}"
        printf "%b\n" "${YELLOW}====================================${RC}"
        echo "1. Install NVIDIA Container Toolkit"
        echo "2. Configure Container Runtime"
        echo "3. Check Installation"
        echo "4. Exit"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) install_nvidia_container_toolkit ;;
            2) configure_runtime ;;
            3) check_installation ;;
            4) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
        esac

        echo "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
menu