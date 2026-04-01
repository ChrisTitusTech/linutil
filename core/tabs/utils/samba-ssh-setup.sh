#!/bin/sh -e

# Load common script functions
# shellcheck disable=SC1091
# shellcheck source=../common-script.sh
. ../common-script.sh
# shellcheck disable=SC1091
# shellcheck source=../common-service-script.sh
. ../common-service-script.sh

# Function to install packages based on the package manager
install_package() {
    PACKAGE=$1
    PACKAGER=${PACKAGER:-}
    if ! command_exists "$PACKAGE"; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$PACKAGE"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add "$PACKAGE"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy "$PACKAGE"
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$PACKAGE"
                ;;
        esac
    else
        echo "$PACKAGE is already installed."
    fi
}       

validate_samba_config() {
    if ! "$ESCALATION_TOOL" testparm -s >/dev/null; then
        printf "%b\n" "${RED}Samba configuration validation failed. Review /etc/samba/smb.conf and try again.${RC}"
        return 1
    fi
}

get_samba_share_path() {
    awk '
        BEGIN { in_share = 0 }
        /^\[Share\]/ { in_share = 1; next }
        /^\[/ { in_share = 0 }
        in_share && $1 == "path" {
            sub(/^[[:space:]]*path[[:space:]]*=[[:space:]]*/, "")
            print
            exit
        }
    ' "$SAMBA_CONFIG"
}

allow_ufw_rule() {
    if "$ESCALATION_TOOL" ufw allow "$1"; then
        return 0
    fi

    if [ -n "$2" ]; then
        "$ESCALATION_TOOL" ufw allow "$2"
    else
        return 1
    fi
}

ufw_rule_exists() {
    "$ESCALATION_TOOL" ufw status | grep -Fq "$1"
}

remove_ufw_rule() {
    if ufw_rule_exists "$1"; then
        printf "y\n" | "$ESCALATION_TOOL" ufw delete allow "$1" >/dev/null
    fi
}

remove_local_ssh_host_entries() {
    SSH_CONFIG="$HOME/.ssh/config"

    if [ ! -f "$SSH_CONFIG" ]; then
        printf "%b\n" "${YELLOW}No local SSH config found at $SSH_CONFIG.${RC}"
        return 0
    fi

    printf "%b" "Enter the SSH host alias to remove (or 'all' to remove all host entries): "
    read -r HOST_ALIAS

    if [ "$HOST_ALIAS" = "all" ]; then
        awk '
            $1 == "Host" { skip = 1; next }
            !skip { print }
        ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp" && mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
        printf "%b\n" "${GREEN}Removed all local SSH host entries from $SSH_CONFIG.${RC}"
        return 0
    fi

    if ! awk -v alias="$HOST_ALIAS" '$1 == "Host" { for (i = 2; i <= NF; i++) if ($i == alias) found = 1 } END { exit found ? 0 : 1 }' "$SSH_CONFIG"; then
        printf "%b\n" "${YELLOW}Host $HOST_ALIAS not found in $SSH_CONFIG.${RC}"
        return 0
    fi

    awk -v alias="$HOST_ALIAS" '
        $1 == "Host" {
            skip = 0
            for (i = 2; i <= NF; i++) {
                if ($i == alias) {
                    skip = 1
                }
            }
        }
        !skip { print }
    ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp" && mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
    printf "%b\n" "${GREEN}Removed local SSH host entry $HOST_ALIAS.${RC}"
}

remove_ssh_service_setup() {
    case "$PACKAGER" in
    apt-get|nala)
        SSH_SERVICE="ssh"
        ;;
    *)
        SSH_SERVICE="sshd"
        ;;
    esac

    stopService "$SSH_SERVICE" || true
    disableService "$SSH_SERVICE" || true
    printf "%b\n" "${GREEN}SSH service setup removed. Package remains installed.${RC}"
}

remove_samba_setup() {
    for service in smb nmb; do
        stopService "$service" || true
        disableService "$service" || true
    done
    printf "%b\n" "${GREEN}Samba service setup removed. Config files and packages were kept.${RC}"
}

remove_ssh_firewall_rules() {
    if command_exists ufw; then
        remove_ufw_rule OpenSSH
        remove_ufw_rule ssh
        remove_ufw_rule 22/tcp
        printf "%b\n" "${GREEN}SSH firewall rules removed from UFW when present.${RC}"
    else
        printf "%b\n" "${YELLOW}UFW is not installed. Skipping SSH firewall rule removal.${RC}"
    fi
}

remove_all_setup() {
    remove_ssh_service_setup
    remove_samba_setup
    remove_ssh_firewall_rules
    remove_local_ssh_host_entries
}

remove_setup_menu() {
    printf "%b\n" "Remove Setup"
    printf "%b\n" "1. Remove SSH service setup"
    printf "%b\n" "2. Remove Samba service setup"
    printf "%b\n" "3. Remove SSH firewall rules"
    printf "%b\n" "4. Remove local SSH host entries"
    printf "%b\n" "5. Remove all"
    printf "%b" "Enter your choice (1-5): "
    read -r REMOVE_CHOICE

    case "$REMOVE_CHOICE" in
        1)
            remove_ssh_service_setup
            ;;
        2)
            remove_samba_setup
            ;;
        3)
            remove_ssh_firewall_rules
            ;;
        4)
            remove_local_ssh_host_entries
            ;;
        5)
            remove_all_setup
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Please enter a number between 1 and 5.${RC}"
            return 1
            ;;
    esac
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
    xbps-install)
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
    SHARED_DIR=

    if [ -f "$SAMBA_CONFIG" ]; then
        printf "%b\n" "${YELLOW}Samba configuration file already exists in $SAMBA_CONFIG.${RC}"
        printf "%b" "Do you want to modify the existing Samba configuration? (Y/n): "
        read -r MODIFY_SAMBA
        if [ "$MODIFY_SAMBA" = "Y" ] || [ "$MODIFY_SAMBA" = "y" ]; then
            "$ESCALATION_TOOL" "$EDITOR" "$SAMBA_CONFIG"
        fi
        SHARED_DIR=$(get_samba_share_path)
    else
        printf "%b\n" "${YELLOW}No existing Samba configuration found. Setting up a new one...${RC}"

        # Prompt user for shared directory path
        printf "%b" "Enter the path for the Samba share (default: /srv/samba/share): "
        read -r SHARED_DIR
        SHARED_DIR=${SHARED_DIR:-/srv/samba/share}

        # Add a new Samba user
        DEFAULT_SAMBA_USER=$(whoami)
        while true; do
            printf "%b" "Enter Samba username (default: ${DEFAULT_SAMBA_USER}): "
            read -r SAMBA_USER
            SAMBA_USER=${SAMBA_USER:-$DEFAULT_SAMBA_USER}
            if id "$SAMBA_USER" >/dev/null 2>&1; then
                break
            fi
            printf "%b\n" "${RED}User ${SAMBA_USER} does not exist on this system. Enter an existing local account.${RC}"
        done

        # Create the shared directory if it doesn't exist and hand it to the Samba user.
        "$ESCALATION_TOOL" mkdir -p "$SHARED_DIR"
        "$ESCALATION_TOOL" chown "$SAMBA_USER":"$(id -gn "$SAMBA_USER")" "$SHARED_DIR"
        "$ESCALATION_TOOL" chmod 0770 "$SHARED_DIR"

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

        validate_samba_config || return 1

        printf "%b\n" "${YELLOW}Set the Samba password for ${SAMBA_USER}.${RC}"
        "$ESCALATION_TOOL" smbpasswd -a "$SAMBA_USER"
    fi

    validate_samba_config || return 1

    for service in smb nmb; do
        startAndEnableService "$service"
    done

    if isServiceActive smb && isServiceActive nmb; then
        printf "%b\n" "${GREEN}Samba is up and running.${RC}"
        if [ -n "$SHARED_DIR" ]; then
            printf "%b\n" "${YELLOW}Samba share available at: $SHARED_DIR${RC}"
        else
            printf "%b\n" "${YELLOW}Samba share path not found in $SAMBA_CONFIG.${RC}"
        fi
    else
        printf "%b\n" "${RED}Failed to start Samba.${RC}"
    fi
}

# Function to configure firewall (optional)
configure_firewall() {
    printf "%b\n" "${BLUE}Configuring firewall...${RC}"

    if command_exists ufw; then
        allow_ufw_rule OpenSSH ssh || {
            printf "%b\n" "${RED}Failed to allow SSH through UFW.${RC}"
            return 1
        }
        allow_ufw_rule Samba 139,445/tcp || {
            printf "%b\n" "${RED}Failed to allow Samba through UFW.${RC}"
            return 1
        }
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
    printf "%b\n" "3. Remove Setup"
    printf "%b\n" "4. Configure Firewall"
    printf "%b\n" "5. Setup All"
    printf "%b\n" "6. Exit"

    printf "%b" "Enter your choice (1-6): "
    read -r CHOICE

    case "$CHOICE" in
        1)
            setup_ssh
            ;;
        2)
            setup_samba
            ;;
        3)
            remove_setup_menu
            ;;
        4)
            configure_firewall
            ;;
        5)
            setup_ssh
            setup_samba
            configure_firewall
            ;;
        6)
            printf "%b\n" "${GREEN}Exiting.${RC}"
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Please enter a number between 1 and 6.${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}Setup completed.${RC}"
}

checkEnv
checkEscalationTool
setup_ssh_samba
