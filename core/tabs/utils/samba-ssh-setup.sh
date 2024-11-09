#!/bin/sh -e

# Load common script functions
. ../common-script.sh  

# Function to install packages based on the package manager
install_package() {
    PACKAGE=$1
    if ! command_exists "$PACKAGE"; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$PACKAGE"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add "$PACKAGE"
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$PACKAGE"
                ;;
        esac
    else
        echo "$PACKAGE is already installed."
    fi
}       

# Function to setup and configure SSH
setup_ssh() {
    printf "%b\n" "${YELLOW}Setting up SSH...${RC}"

    # Detect package manager and install appropriate SSH package
    case "$PACKAGER" in
    apt-get|nala)
        install_package openssh-server
        SSH_SERVICE="ssh"
        ;;
    pacman)
        install_package openssh
        SSH_SERVICE="sshd"
        ;;
    apk)
        install_package openssh
        SSH_SERVICE="sshd"
        ;;
    *)
        install_package openssh-server
        SSH_SERVICE="sshd"
        ;;
    esac

    startAndEnableService "$SSH_SERVICE"

    LOCAL_IP=$(ip -4 addr show | awk '/inet / {print $2}' | tail -n 1)

    printf "%b\n" "${GREEN}Your local IP address is: $LOCAL_IP${RC}"

    if isServiceActive "$SSH_SERVICE"; then
        printf "%b\n" "${GREEN}SSH is up and running.${RC}"
    else
        printf "%b\n" "${RED}Failed to start SSH.${RC}"
    fi
}

# Function to setup and configure Samba
setup_samba() {
    printf "%b\n" "${YELLOW}Setting up Samba...${RC}"
    
    # Install Samba if not installed
    install_package samba

    SAMBA_CONFIG="/etc/samba/smb.conf"

    if [ -f "$SAMBA_CONFIG" ]; then
        printf "%b\n" "${YELLOW}Samba configuration file already exists in $SAMBA_CONFIG.${RC}"
        printf "%b" "Do you want to modify the existing Samba configuration? (Y/n): "
        read -r MODIFY_SAMBA
        if [ "$MODIFY_SAMBA" = "Y" ] || [ "$MODIFY_SAMBA" = "y" ]; then
            "$ESCALATION_TOOL" "$EDITOR" "$SAMBA_CONFIG"
        fi
    else
        printf "%b\n" "${YELLOW}No existing Samba configuration found. Setting up a new one...${RC}"

        # Prompt user for shared directory path
        printf "%b" "Enter the path for the Samba share (default: /srv/samba/share): "
        read -r SHARED_DIR
        SHARED_DIR=${SHARED_DIR:-/srv/samba/share}

        # Create the shared directory if it doesn't exist
        "$ESCALATION_TOOL" mkdir -p "$SHARED_DIR"
        "$ESCALATION_TOOL" chmod -R 0777 "$SHARED_DIR"

        # Add a new Samba user
        printf "%b" "Enter Samba username: "
        read -r SAMBA_USER

        # Loop until the passwords match
        while true; do
            printf "Enter Samba password: "
            stty -echo
            read -r SAMBA_PASSWORD
            stty echo
            printf "Confirm Samba password: "
            stty -echo
            read -r SAMBA_PASSWORD_CONFIRM
            stty echo
            printf "\n"
            if [ "$SAMBA_PASSWORD" = "$SAMBA_PASSWORD_CONFIRM" ]; then
                printf "%b\n" "${GREEN}Passwords match.${RC}"
                break
            else
                printf "%b\n" "${RED}Passwords do not match. Please try again.${RC}"
            fi
        done

        # Add the user and set the password
        "$ESCALATION_TOOL" smbpasswd -a "$SAMBA_USER"

        # Configure Samba settings
        "$ESCALATION_TOOL" tee "$SAMBA_CONFIG" > /dev/null <<EOL
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   security = user
   map to guest = bad user
   dns proxy = no

[Share]
   path = $SHARED_DIR
   browsable = yes
   writable = yes
   guest ok = no
   read only = no
   valid users = $SAMBA_USER
EOL
    fi

    for service in smb nmb; do
        startAndEnableService "$service"
    done

    if isServiceActive smb && isServiceActive nmb; then
        printf "%b\n" "${GREEN}Samba is up and running.${RC}"
        printf "%b\n" "${YELLOW}Samba share available at: $SHARED_DIR${RC}"
    else
        printf "%b\n" "${RED}Failed to start Samba.${RC}"
    fi
}

# Function to configure firewall (optional)
configure_firewall() {
    printf "%b\n" "${BLUE}Configuring firewall...${RC}"

    if command_exists ufw; then
        "$ESCALATION_TOOL" ufw allow OpenSSH
        "$ESCALATION_TOOL" ufw allow Samba
        "$ESCALATION_TOOL" ufw enable
        printf "%b\n" "${GREEN}Firewall configured for SSH and Samba.${RC}"
    else
        printf "%b\n" "${YELLOW}UFW is not installed. Skipping firewall configuration.${RC}"
    fi
}

setup_ssh_samba(){
    printf "%b\n" "Samba and SSH Setup Script"
    printf "%b\n" "--------------------------"
    clear

    # Display menu
    printf "%b\n" "Select an option:"
    printf "%b\n" "1. Setup SSH"
    printf "%b\n" "2. Setup Samba"
    printf "%b\n" "3. Configure Firewall"
    printf "%b\n" "4. Setup All"
    printf "%b\n" "5. Exit"

    printf "%b" "Enter your choice (1-5): "
    read CHOICE

    case "$CHOICE" in
        1)
            setup_ssh
            ;;
        2)
            setup_samba
            ;;
        3)
            configure_firewall
            ;;
        4)
            setup_ssh
            setup_samba
            configure_firewall
            ;;
        5)
            printf "%b\n" "${GREEN}Exiting.${RC}"
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Please enter a number between 1 and 5.${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}Setup completed.${RC}"
}

checkEnv
checkEscalationTool
setup_ssh_samba