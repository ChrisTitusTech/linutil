#!/bin/sh -e

. ../common-script.sh

checkKVMSupport() {
    # check kvm enabled using cpuinfo
    if [ "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" -eq 0 ]; then
        echo "KVM is not supported on this machine. Please enable virtualization in BIOS."
        echo "KVM is an acceleration feature for QEMU, which allows you to run virtual machines at near-native speed."
        echo "It is recommended to enable KVM for better performance."
        # ask if the user wants to continue
        read -r -p "Do you want to continue without KVM support? [y/N] " response
        case "$response" in
        [yY][eE][sS] | [yY])
            echo "Continuing without KVM support..."
            ;;
        *)
            echo "Exiting..."
            exit 1
            ;;
        esac
    else
        echo "KVM is supported on this machine."
        # Add user to the kvm group
        $ESCALATION_TOOL usermod -aG kvm $USER
    fi
    echo "KVM is supported on this machine."
}

check64Bit() {
    # check  if the os is 64 bit
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "This script is only for 64-bit systems."
        exit 1
    fi
    echo "This is a 64-bit system."
}


installDockerArch() {
    echo "Install Docker if not already installed..."
    if ! command_exists docker; then
        $ESCALATION_TOOL pacman -S docker docker-compose docker-buildx --noconfirm
        $ESCALATION_TOOL systemctl enable docker.service
        $ESCALATION_TOOL systemctl start docker.service
    else
        echo "Docker is already installed."
    fi
}

installDocker() {
    # Install Docker based on the package manager
    case "$PACKAGER" in
    apt-get | apt | dnf)
        curl -fsSL https://get.docker.com/ | sh
        ;;
    pacman)
        installDockerArch
        ;;
    *)
        echo "Unsupported package manager: $PACKAGER"
        exit 1
        ;;
    esac
}

setupDocker() {
    echo "Setting up Docker..."
    installDocker
    # Start and enable the Docker service
    $ESCALATION_TOOL systemctl enable docker.service
    $ESCALATION_TOOL systemctl start docker.service
    $ESCALATION_TOOL systemctl enable docker.socket
    $ESCALATION_TOOL systemctl start docker.socket
    $ESCALATION_TOOL systemctl enable docker
    $ESCALATION_TOOL systemctl start docker
   # Add user to the docker group
    $ESCALATION_TOOL groupadd docker
    $ESCALATION_TOOL usermod -aG docker $USER
    docker run hello-world
    echo "Docker setup successfully"
}

checkEnv
checkEscalationTool
checkKVMSupport
check64Bit
setupDocker
