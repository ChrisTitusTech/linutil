#!/bin/bash

# Install necessary packages
sudo apt update
sudo apt install neovim tmux btop nvtop ubuntu-drivers-common ca-certificates curl -y

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    # Remove any existing Docker installations
    sudo apt-get remove docker docker-engine docker.io containerd runc -y
    
    # Set up Docker repository and install Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    
    # Add Docker group to all users
    for user in $(cut -d: -f1 /etc/passwd); do
        sudo usermod -aG docker $user
    done
fi

# Install lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo DIR="/usr/local/bin" bash
sudo sh -c 'echo "alias lzd=lazydocker" >> /etc/bash.bashrc'
# install lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
# Clean up unused packages
sudo apt autoremove -y

reboot_required=false

# Check for NVIDIA GPUs
if lspci | grep -i nvidia; then
    # Install NVIDIA container toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    sudo ubuntu-drivers autoinstall
    reboot_required=true

    # Create and schedule post-reboot script
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
fi

# Conditionally reboot the system if required
if [ "$reboot_required" = true ]; then
    sudo reboot
fi
