#!/bin/sh -e

. ../common-script.sh

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt-get"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PACKAGE_MANAGER="yum"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
    else
        PACKAGE_MANAGER=""
    fi
}

install_dependencies() {
    printf "%b\n" "Installing required dependencies..."
    if [ -z "$PACKAGE_MANAGER" ]; then
        printf "%b\n" "PACKAGE_MANAGER is not set. Attempting to detect..."
        detect_package_manager
        if [ -z "$PACKAGE_MANAGER" ]; then
            printf "%b\n" "Error: Unable to detect package manager."
            printf "%b\n" "Please set PACKAGE_MANAGER manually before running this script."
            return 1
        fi
    fi
    printf "Using package manager: %s\n" "$PACKAGE_MANAGER"
    
    # Check if running as root, if not, use sudo
    if [ "$(id -u)" -ne 0 ]; then
        printf "%b\n" "This operation requires superuser privileges."
        printf "%b\n" "Please enter your sudo password when prompted."
        SUDO="sudo"
    else
        SUDO=""
    fi

    case "$PACKAGE_MANAGER" in
        apt-get|nala)
            $SUDO "$PACKAGE_MANAGER" update
            $SUDO "$PACKAGE_MANAGER" install -y nfs-common cifs-utils
            ;;
        dnf|yum)
            $SUDO "$PACKAGE_MANAGER" install -y nfs-utils cifs-utils
            ;;
        pacman)
            $SUDO "$PACKAGE_MANAGER" -Sy --noconfirm nfs-utils cifs-utils
            ;;
        zypper)
            $SUDO "$PACKAGE_MANAGER" refresh
            $SUDO "$PACKAGE_MANAGER" install -y nfs-client cifs-utils
            ;;
        *)
            printf "%b\n" "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        printf "%b\n" "Dependencies installed successfully."
    else
        printf "%b\n" "Error: Failed to install dependencies."
        return 1
    fi
}

setup_nfs() {
    printf "%b\n" "Setting up NFS share..."
    printf "Enter the NFS server IP address: "
    read -r server_ip
    printf "Enter the NFS share path on the server: "
    read -r share_path
    printf "Enter the local mount point: "
    read -r mount_point

    # Create mount point if it doesn't exist
    if [ ! -d "$mount_point" ]; then
        sudo mkdir -p "$mount_point"
        if [ $? -ne 0 ]; then
            printf "%b\n" "Error: Failed to create mount point directory."
            return 1
        fi
    fi

    # Add entry to fstab
    fstab_entry="$server_ip:$share_path $mount_point nfs defaults 0 0"
    printf "%b\n" "Adding the following entry to /etc/fstab:"
    printf "%s\n" "$fstab_entry"
    printf "Is this correct? (y/n) "
    read -r confirm
    if [ "$confirm" = "y" ]; then
        echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
        if [ $? -eq 0 ]; then
            printf "%b\n" "Entry added to /etc/fstab"
            sudo mount -a
            if [ $? -eq 0 ]; then
                printf "%b\n" "NFS share mounted successfully"
            else
                printf "%b\n" "Failed to mount NFS share. Please check the fstab entry and try again."
            fi
        else
            printf "%b\n" "Failed to add entry to /etc/fstab"
        fi
    else
        printf "%b\n" "Aborted adding entry to /etc/fstab"
    fi
}

setup_cifs() {
    printf "%b\n" "Setting up CIFS/SMB share..."
    printf "Enter the CIFS/SMB server IP address: "
    read -r server_ip
    printf "Enter the CIFS/SMB share name: "
    read -r share_name
    printf "Enter the local mount point: "
    read -r mount_point
    printf "Enter the username for the CIFS/SMB share: "
    read -r username
    printf "Enter the password for the CIFS/SMB share: "
    read -rs password
    echo

    # Create mount point if it doesn't exist
     mkdir -p ""

    # Create credentials file
    cred_file="/root/.smbcredentials_"
    printf "username=%s\npassword=%s\n" "" "" |  tee "" > /dev/null
     chmod 600 ""

    # Add entry to fstab
    fstab_entry="///  cifs credentials=,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"
    printf "%b\n" "Adding the following entry to /etc/fstab:"
    printf "%s\n" ""
    printf "Is this correct? (y/n) "
    read -r confirm
    if [ "" = "y" ]; then
        echo "" |  tee -a /etc/fstab > /dev/null
        printf "%b\n" "Entry added to /etc/fstab"
         mount -a
        if [ 130 -eq 0 ]; then
            printf "%b\n" "CIFS/SMB share mounted successfully"
        else
            printf "%b\n" "Failed to mount CIFS/SMB share. Please check the fstab entry and try again."
        fi
    else
        printf "%b\n" "Aborted adding entry to /etc/fstab"
    fi
}

menu() {
    while true; do
        clear
        printf "%b\n" "NAS Setup"
        printf "%b\n" "========="
        echo "1. Install dependencies"
        echo "2. Setup NFS share"
        echo "3. Setup CIFS/SMB share"
        echo "4. Exit"
        echo -n "Choose an option: "
        read -r choice

        case "$choice" in
            1) install_dependencies ;;
            2) setup_nfs ;;
            3) setup_cifs ;;
            4) exit 0 ;;
            *) printf "%b\n" "Invalid option. Please try again." ;;
        esac

        echo "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
menu
