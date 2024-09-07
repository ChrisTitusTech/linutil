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

installDockerUbuntu() {
    echo "Install Docker if not already installed..."
    if ! command_exists docker; then
        # Add Docker's official GPG key:
        $ESCALATION_TOOL apt-get update
        $ESCALATION_TOOL apt-get install ca-certificates curl -y
        $ESCALATION_TOOL install -m 0755 -d /etc/apt/keyrings
        $ESCALATION_TOOL curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        $ESCALATION_TOOL chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$(. /etc/os-release && echo "$VERSION_CODENAME")") stable" |
            $ESCALATION_TOOL tee /etc/apt/sources.list.d/docker.list >/dev/null
        $ESCALATION_TOOL apt-get update
        # Install Docker and its dependencies:
        $ESCALATION_TOOL apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        echo "Docker is already installed."
    fi
}

installDockerDebian() {
    echo "Install Docker if not already installed..."
    if ! command_exists docker; then
        # Add Docker's official GPG key:
        $ESCALATION_TOOL apt-get update
        $ESCALATION_TOOL apt-get install ca-certificates curl
        $ESCALATION_TOOL install -m 0755 -d /etc/apt/keyrings
        $ESCALATION_TOOL curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        $ESCALATION_TOOL chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$(. /etc/os-release && echo "$VERSION_CODENAME")") stable" |
            $ESCALATION_TOOL tee /etc/apt/sources.list.d/docker.list >/dev/null
        $ESCALATION_TOOL apt-get update
        # Install Docker and its dependencies:
        $ESCALATION_TOOL apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    else
        echo "Docker is already installed."
    fi
}

installDockerFedora() {
    echo "Install Docker if not already installed..."
    if ! command_exists docker; then
        $ESCALATION_TOOL dnf -y install dnf-plugins-core
        $ESCALATION_TOOL dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        $ESCALATION_TOOL dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        $ESCALATION_TOOL systemctl start docker
    else
        echo "Docker is already installed."
    fi
}

installDockerArch() {
    echo "Install Docker if not already installed..."
    if ! command_exists docker; then
        $ESCALATION_TOOL pacman -S docker
        $ESCALATION_TOOL systemctl enable docker.service
        $ESCALATION_TOOL systemctl start docker.service
    else
        echo "Docker is already installed."
    fi
}

installDocker() {
    # Install Docker based on the package manager
    case "$PACKAGER" in
    apt-get)
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            # check if the $ID is ubuntu
            if [ "$ID" = "ubuntu" ]; then
                installDockerUbuntu
            elif [ "$ID" = "debian" ]; then
                installDockerDebian
            # check if the $ID_LIKE contains ubuntu
            elif [[ "$ID_LIKE" =~ "ubuntu" ]]; then
                installDockerUbuntu
            elif [[ "$ID_LIKE" =~ "debian" ]]; then
                installDockerDebian
            else
                echo "Unsupported distribution"
                exit 1
            fi

        else
            echo "Unsupported distribution"
            exit 1
        fi
        ;;
    dnf)
        installDockerFedora
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

# Add user to the kvm group
$ESCALATION_TOOL usermod -aG kvm $USER

setupDocker
