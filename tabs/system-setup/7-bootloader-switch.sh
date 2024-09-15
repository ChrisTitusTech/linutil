#!/bin/sh -e

# Load common functions and environment checks from common-script.sh
. ../common-script.sh

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
        printf "GRUB\n"
    elif [ -d /boot/loader ]; then
        printf "systemd-boot\n"
    else
        printf "Unknown\n"
    fi
}

# Backup GRUB configuration
backup_grub() {
    create_backup_dir
    printf "${YELLOW}Backing up GRUB configuration...${RC}\n"
    $ESCALATION_TOOL tar -czf "$BACKUP_DIR/grub-backup-$TIMESTAMP.tar.gz" /boot/grub /etc/default/grub /etc/grub.d
    printf "${GREEN}GRUB configuration backed up to $BACKUP_DIR/grub-backup-$TIMESTAMP.tar.gz${RC}\n"
}

# Backup systemd-boot configuration
backup_systemd_boot() {
    create_backup_dir
    printf "${YELLOW}Backing up systemd-boot configuration...${RC}\n"
    $ESCALATION_TOOL tar -czf "$BACKUP_DIR/systemd-boot-backup-$TIMESTAMP.tar.gz" /boot/loader
    printf "${GREEN}systemd-boot configuration backed up to $BACKUP_DIR/systemd-boot-backup-$TIMESTAMP.tar.gz${RC}\n"
}

# Restore GRUB configuration
restore_grub() {
    if [ -z "$1" ]; then
        printf "${RED}Please provide the backup file for GRUB restore.${RC}\n"
        exit 1
    fi

    printf "${YELLOW}Restoring GRUB configuration from %s...${RC}\n" "$1"
    $ESCALATION_TOOL tar -xzf "$1" -C /
    grub-mkconfig -o /boot/grub/grub.cfg
    printf "${GREEN}GRUB configuration restored.${RC}\n"
}

# Restore systemd-boot configuration
restore_systemd_boot() {
    if [ -z "$1" ]; then
        printf "${RED}Please provide the backup file for systemd-boot restore.${RC}\n"
        exit 1
    fi

    printf "${YELLOW}Restoring systemd-boot configuration from %s...${RC}\n" "$1"
    $ESCALATION_TOOL tar -xzf "$1" -C /
    printf "${GREEN}systemd-boot configuration restored.${RC}\n"
}

# Switch to GRUB bootloader
switch_to_grub() {
    backup_systemd_boot  # Backup systemd-boot before switching
    printf "${YELLOW}Switching to GRUB...${RC}\n"

    case "$DTYPE" in
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
            printf "${RED}Unsupported distribution for GRUB installation.${RC}\n"
            exit 1
            ;;
    esac
}

# Switch to systemd-boot bootloader
switch_to_systemd_boot() {
    backup_grub  # Backup GRUB before switching
    printf "${YELLOW}Switching to systemd-boot...${RC}\n"

    case "$DTYPE" in
        debian | ubuntu | arch | fedora)
            $ESCALATION_TOOL bootctl install
            ;;
        *)
            printf "${RED}Unsupported distribution for systemd-boot installation.${RC}\n"
            exit 1
            ;;
    esac
}

# Display list of backups for user to choose
display_backup_list() {
    printf "${YELLOW}Available backups:${RC}\n"
    ls -1 "$BACKUP_DIR" | grep -E 'grub-backup|systemd-boot-backup'
}

# Interactive menu for bootloader switching
menu() {
    CURRENT_BOOTLOADER=$(detect_bootloader)

    printf "${YELLOW}Current bootloader detected: %s${RC}\n" "$CURRENT_BOOTLOADER"
    if [ "$CURRENT_BOOTLOADER" = "GRUB" ]; then
        printf "${YELLOW}1) Switch to systemd-boot${RC}\n"
    elif [ "$CURRENT_BOOTLOADER" = "systemd-boot" ]; then
        printf "${YELLOW}1) Switch to GRUB${RC}\n"
    fi
    printf "${YELLOW}2) Restore backup${RC}\n"
    printf "${YELLOW}3) Exit${RC}\n"
    printf "Choose an option: "
    read option

    case "$option" in
        1)
            if [ "$CURRENT_BOOTLOADER" = "GRUB" ]; then
                switch_to_systemd_boot
            elif [ "$CURRENT_BOOTLOADER" = "systemd-boot" ]; then
                switch_to_grub
            else
                printf "${RED}Unknown bootloader detected. Cannot switch.${RC}\n"
            fi
            ;;
        2)
            display_backup_list
            printf "${YELLOW}Enter the name of the backup file to restore: ${RC}"
            read backup_file
            if echo "$backup_file" | grep -q "grub-backup"; then
                restore_grub "$BACKUP_DIR/$backup_file"
            elif echo "$backup_file" | grep -q "systemd-boot-backup"; then
                restore_systemd_boot "$BACKUP_DIR/$backup_file"
            else
                printf "${RED}Invalid backup file selected.${RC}\n"
            fi
            ;;
        3)
            printf "${GREEN}Exiting.${RC}\n"
            exit 0
            ;;
        *)
            printf "${RED}Invalid option selected.${RC}\n"
            exit 1
            ;;
    esac
}

# Main script execution
checkEnv
checkEscalationTool
menu
