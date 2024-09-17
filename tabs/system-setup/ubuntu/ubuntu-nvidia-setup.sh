#!/bin/sh -e

. ../../common-script.sh

ubuntu_nvidia_setup() {
    # Install necessary packages
    $ESCALATION_TOOL apt update
    $ESCALATION_TOOL apt install neovim tmux btop nvtop ubuntu-drivers-common ca-certificates curl -y

    # Check if Docker is installed
    if ! command -v docker &> /dev/null
    then
        # Remove any existing Docker installations
        $ESCALATION_TOOL apt-get remove docker docker-engine docker.io containerd runc -y
        
        # Set up Docker repository and install Docker
        $ESCALATION_TOOL install -m 0755 -d /etc/apt/keyrings
        $ESCALATION_TOOL curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        $ESCALATION_TOOL chmod a+r /etc/apt/keyrings/docker.asc

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $ESCALATION_TOOL tee /etc/apt/sources.list.d/docker.list >/dev/null

        $ESCALATION_TOOL apt-get update
        $ESCALATION_TOOL apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        
        # Add Docker group to all users
        for user in $(cut -d: -f1 /etc/passwd); do
            $ESCALATION_TOOL usermod -aG docker $user
        done
    fi

    # Install lazydocker
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | $ESCALATION_TOOL DIR="/usr/local/bin" bash
    $ESCALATION_TOOL sh -c 'echo "alias lzd=lazydocker" >> /etc/bash.bashrc'
    
    # Install lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    $ESCALATION_TOOL install lazygit /usr/local/bin
    
    # Clean up unused packages
    $ESCALATION_TOOL apt autoremove -y

    # Check for NVIDIA GPUs
    if lspci | grep -i nvidia; then
        # Install NVIDIA container toolkit
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | $ESCALATION_TOOL gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        $ESCALATION_TOOL tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        $ESCALATION_TOOL apt-get update
        $ESCALATION_TOOL apt-get install -y nvidia-container-toolkit
        $ESCALATION_TOOL nvidia-ctk runtime configure --runtime=docker
        $ESCALATION_TOOL systemctl restart docker
        $ESCALATION_TOOL ubuntu-drivers autoinstall

        printf "%b\n" "${YELLOW}NVIDIA drivers installed. A reboot is required to complete the setup.${RC}"
        printf "%b\n" "${YELLOW}After reboot, the following packages will be installed: build-essential and linux-headers-$(uname -r)${RC}"
        
        # Create post-reboot script
        cat << 'EOF' > /tmp/post_reboot_script.sh
#!/bin/bash
# Remove existing packages if they exist
if dpkg -l | grep -q build-essential; then
    sudo apt-get remove --purge build-essential -y
fi
if dpkg -l | grep -q "linux-headers-$(uname -r)"; then
    sudo apt-get remove --purge "linux-headers-$(uname -r)" -y
fi
# Install packages after removal
sudo apt-get install build-essential linux-headers-$(uname -r) -y
sudo reboot
EOF
        chmod +x /tmp/post_reboot_script.sh
        (crontab -l 2>/dev/null; echo "@reboot /tmp/post_reboot_script.sh") | crontab -

        # Prompt for reboot
        printf "%b\n" "${YELLOW}A reboot is required to complete the setup. Do you want to reboot now? (y/n)${RC}"
        read -r reboot_choice
        if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
            $ESCALATION_TOOL reboot
        else
            printf "%b\n" "${YELLOW}Please reboot your system manually to complete the setup.${RC}"
        fi
    else
        printf "%b\n" "${YELLOW}No NVIDIA GPU detected. Skipping NVIDIA driver installation.${RC}"
    fi
}

checkEnv
checkEscalationTool
ubuntu_nvidia_setup