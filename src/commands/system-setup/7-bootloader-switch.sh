#!/bin/sh -e

# Load common functions and environment checks from common-script.sh
. ./common-script.sh

BACKUP_DIR="/boot/backup/bootloader"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        $ESCALATION_TOOL mkdir -p "$BACKUP_DIR"
    fi
}

# Detect current bootloader
detect_bootloader() {
    if [ -d /boot/grub ]; then
        echo "GRUB"
    elif [ -d /boot/loader ]; then
        echo "systemd-boot"
    else
        echo "Unknown"
    fi
}

# Backup GRUB configuration
backup_grub() {
    create_backup_dir
    echo "${YELLOW}Backing up GRUB configuration...${RC}"
    $ESCALATION_TOOL tar -czf "$BACKUP_DIR/grub-backup-$TIMESTAMP.tar.gz" /boot/grub /etc/default/grub /etc/grub.d
    echo "${GREEN}GRUB configuration backed up to $BACKUP_DIR/grub-backup-$TIMESTAMP.tar.gz${RC}"
}

# Backup systemd-boot configuration
backup_systemd_boot() {
    create_backup_dir
    echo "${YELLOW}Backing up systemd-boot configuration...${RC}"
    $ESCALATION_TOOL tar -czf "$BACKUP_DIR/systemd-boot-backup-$TIMESTAMP.tar.gz" /boot/loader
    echo "${GREEN}systemd-boot configuration backed up to $BACKUP_DIR/systemd-boot-backup-$TIMESTAMP.tar.gz${RC}"
}

# Restore GRUB configuration
restore_grub() {
    if [ -z "$1" ]; then
        echo "${RED}Please provide the backup file for GRUB restore.${RC}"
        exit 1
    fi

    echo "${YELLOW}Restoring GRUB configuration from $1...${RC}"
    $ESCALATION_TOOL tar -xzf "$1" -C /
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "${GREEN}GRUB configuration restored.${RC}"
}

# Restore systemd-boot configuration
restore_systemd_boot() {
    if [ -z "$1" ]; then
        echo "${RED}Please provide the backup file for systemd-boot restore.${RC}"
        exit 1
    fi

    echo "${YELLOW}Restoring systemd-boot configuration from $1...${RC}"
    $ESCALATION_TOOL tar -xzf "$1" -C /
    echo "${GREEN}systemd-boot configuration restored.${RC}"
}

# Switch to GRUB bootloader
switch_to_grub() {
    backup_systemd_boot  # Backup systemd-boot before switching
    echo "${YELLOW}Switching to GRUB...${RC}"

    case $DTYPE in
        debian | ubuntu)
            $ESCALATION_TOOL apt-get install -y grub-efi
            grub-install
            grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        arch)
            $ESCALATION_TOOL pacman -S --noconfirm grub
            grub-install --target=x86_64-efi --efi-directory=/boot
            grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        fedora)
            $ESCALATION_TOOL dnf install -y grub2-efi
            grub2-install
            grub2-mkconfig -o /boot/grub2/grub.cfg
            ;;
        *)
            echo "${RED}Unsupported distribution for GRUB installation.${RC}"
            exit 1
            ;;
    esac
}

# Switch to systemd-boot bootloader
switch_to_systemd_boot() {
    backup_grub  # Backup GRUB before switching
    echo "${YELLOW}Switching to systemd-boot...${RC}"

    case $DTYPE in
        debian | ubuntu | arch | fedora)
            $ESCALATION_TOOL bootctl install
            ;;
        *)
            echo "${RED}Unsupported distribution for systemd-boot installation.${RC}"
            exit 1
            ;;
    esac
}

# Display list of backups for user to choose
display_backup_list() {
    echo "${YELLOW}Available backups:${RC}"
    ls -1 $BACKUP_DIR | grep -E 'grub-backup|systemd-boot-backup'
}

# Interactive menu for bootloader switching
menu() {
    CURRENT_BOOTLOADER=$(detect_bootloader)

    echo "${YELLOW}Current bootloader detected: $CURRENT_BOOTLOADER${RC}"
    if [ "$CURRENT_BOOTLOADER" = "GRUB" ]; then
        echo "${YELLOW}1) Switch to systemd-boot${RC}"
    elif [ "$CURRENT_BOOTLOADER" = "systemd-boot" ]; then
        echo "${YELLOW}1) Switch to GRUB${RC}"
    fi
    echo "${YELLOW}2) Restore backup${RC}"
    echo "${YELLOW}3) Exit${RC}"
    echo -n "Choose an option: "
    read -r option

    case $option in
        1)
            if [ "$CURRENT_BOOTLOADER" = "GRUB" ]; then
                switch_to_systemd_boot
            elif [ "$CURRENT_BOOTLOADER" = "systemd-boot" ]; then
                switch_to_grub
            else
                echo "${RED}Unknown bootloader detected. Cannot switch.${RC}"
            fi
            ;;
        2)
            display_backup_list
            echo -n "${YELLOW}Enter the name of the backup file to restore: ${RC}"
            read -r backup_file
            if echo "$backup_file" | grep -q "grub-backup"; then
                restore_grub "$BACKUP_DIR/$backup_file"
            elif echo "$backup_file" | grep -q "systemd-boot-backup"; then
                restore_systemd_boot "$BACKUP_DIR/$backup_file"
            else
                echo "${RED}Invalid backup file selected.${RC}"
            fi
            ;;
        3)
            echo "${GREEN}Exiting.${RC}"
            exit 0
            ;;
        *)
            echo "${RED}Invalid option selected.${RC}"
            exit 1
            ;;
    esac
}

# Check environment and prerequisites
checkEnv

# Run the menu function for user interaction
menu
