#!/bin/sh -e

. ../common-script.sh

# Function to install Timeshift
install_timeshift() {
    clear
    printf "%b\n" "${YELLOW}Checking if Timeshift is installed...${RC}"

     if ! command_exists timeshift; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --noconfirm timeshift
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y timeshift
                ;;
        esac
    else
        echo "Timeshift is already installed."
    fi
}

# Function to display the menu
display_menu() {
    clear
    printf "%b\n" "${CYAN}Timeshift CLI Automation${RC}"
    printf "%b\n" "${CYAN}\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
    printf "%b\n" "${CYAN}1) List Snapshots${RC}"
    printf "%b\n" "${CYAN}2) List Devices${RC}"
    printf "%b\n" "${CYAN}3) Create Snapshot${RC}"
    printf "%b\n" "${CYAN}4) Restore Snapshot${RC}"
    printf "%b\n" "${CYAN}5) Delete Snapshot${RC}"
    printf "%b\n" "${CYAN}6) Delete All Snapshots${RC}"
    printf "%b\n" "${CYAN}7) Exit${RC}"
    printf "%b\n" "${CYAN}\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
}

# Function to list snapshots
list_snapshots() {
    printf "%b\n" "${CYAN}Listing snapshots...${RC}"
    $ESCALATION_TOOL timeshift --list-snapshots
}

# Function to list devices
list_devices() {
    printf "%b\n" "${CYAN}Listing available devices...${RC}"
    $ESCALATION_TOOL timeshift --list-devices
}

# Function to create a new snapshot
create_snapshot() {
    printf "%b" "${CYAN}Enter a comment for the snapshot (optional): ${RC}"
    read -r COMMENT
    printf "%b" "${CYAN}Enter snapshot tag (O,B,H,D,W,M) (leave empty for no tag): ${RC}"
    read -r TAG

    if [ -z "$COMMENT" ] && [ -z "$TAG" ]; then
        echo "Creating snapshot with no comment or tag..."
        $ESCALATION_TOOL timeshift --create
    elif [ -z "$TAG" ]; then
        echo "Creating snapshot with no tag..."
        $ESCALATION_TOOL timeshift --create --comments "$COMMENT"
    else
        echo "Creating snapshot with tag: $TAG..."
        $ESCALATION_TOOL timeshift --create --comments "$COMMENT" --tags "$TAG"
    fi

    if [ $? -eq 0 ]; then
        echo "Snapshot created successfully."
    else
        echo "Snapshot creation failed."
    fi
}

# Function to restore a snapshot
restore_snapshot() {
    list_snapshots

    printf "%b" "${CYAN}Enter the snapshot name you want to restore: ${RC}"
    read -r SNAPSHOT
    printf "%b" "${CYAN}Enter the target device (e.g., /dev/sda1): ${RC}"
    read -r TARGET_DEVICE
    printf "%b" "${CYAN}Do you want to skip GRUB reinstall? (yes/no): ${RC}"
    read -r SKIP_GRUB

    if [ "$SKIP_GRUB" = "yes" ]; then
        $ESCALATION_TOOL timeshift --restore --snapshot "$SNAPSHOT" --target-device "$TARGET_DEVICE" --skip-grub --yes
    else
        printf "%b" "${CYAN}Enter GRUB device (e.g., /dev/sda): ${RC}"
        read -r GRUB_DEVICE
        $ESCALATION_TOOL timeshift --restore --snapshot "$SNAPSHOT" --target-device "$TARGET_DEVICE" --grub-device "$GRUB_DEVICE" --yes
    fi

    if [ $? -eq 0 ]; then
        printf "%b\n" "${GREEN}Snapshot restored successfully.${RC}"
    else
        printf "%b\n" "${RED}Snapshot restore failed.${RC}"
    fi
}

# Function to delete a snapshot
delete_snapshot() {
    list_snapshots

    printf "%b" "${CYAN}Enter the snapshot name you want to delete: ${RC}"
    read -r SNAPSHOT

    printf "%b\n" "${YELLOW}Deleting snapshot $SNAPSHOT...${RC}"
    $ESCALATION_TOOL timeshift --delete --snapshot "$SNAPSHOT" --yes

    if [ $? -eq 0 ]; then
        printf "%b\n" "${GREEN}Snapshot deleted successfully.${RC}"
    else
        printf "%b\n" "${RED}Snapshot deletion failed.${RC}"
    fi
}

# Function to delete all snapshots
delete_all_snapshots() {
    printf "%b\n" "${RED}WARNING: This will delete all snapshots!${RC}"
    printf "%b" "${CYAN}Are you sure? (yes/no): ${RC}"
    read -r CONFIRMATION

    if [ "$CONFIRMATION" = "yes" ]; then
        echo "Deleting all snapshots..."
        $ESCALATION_TOOL timeshift --delete-all --yes
        if [ $? -eq 0 ]; then
            printf "%b\n" "${GREEN}All snapshots deleted successfully.${RC}"
        else
            printf "%b\n" "${RED}Failed to delete snapshots.${RC}"
        fi
    else
        printf "%b\n" "${RED}Operation cancelled.${RC}"
    fi
}

main_menu() {
while true; do
    display_menu
    printf "%b" "${CYAN}Select an option (1-7): ${RC}"
    read -r OPTION

    case $OPTION in
        1) list_snapshots ;;
        2) list_devices ;;
        3) create_snapshot ;;
        4) restore_snapshot ;;
        5) delete_snapshot ;;
        6) delete_all_snapshots ;;
        7) printf "%b\n" "${GREEN}Exiting...${RC}"; exit 0 ;;
        *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
    esac
    printf "%b" "${CYAN}Press Enter to continue...${RC}"
    read -r dummy
done
}

checkEnv
checkEscalationTool
install_timeshift  
main_menu
