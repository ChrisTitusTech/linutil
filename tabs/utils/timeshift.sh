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
    echo "Timeshift CLI Automation"
    echo "-------------------------"
    echo "1) List Snapshots"
    echo "2) List Devices"
    echo "3) Create Snapshot"
    echo "4) Restore Snapshot"
    echo "5) Delete Snapshot"
    echo "6) Delete All Snapshots"
    echo "7) Exit"
    echo ""
}

# Function to list snapshots
list_snapshots() {
    echo "Listing snapshots..."
    $ESCALATION_TOOL timeshift --list-snapshots
}

# Function to list devices
list_devices() {
    echo "Listing available devices..."
    $ESCALATION_TOOL timeshift --list-devices
}

# Function to create a new snapshot
create_snapshot() {
    read -p "Enter a comment for the snapshot (optional): " COMMENT
    read -p "Enter snapshot tag (O,B,H,D,W,M) (leave empty for no tag): " TAG

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

    read -p "Enter the snapshot name you want to restore: " SNAPSHOT
    read -p "Enter the target device (e.g., /dev/sda1): " TARGET_DEVICE
    read -p "Do you want to skip GRUB reinstall? (yes/no): " SKIP_GRUB

    if [ "$SKIP_GRUB" = "yes" ]; then
        $ESCALATION_TOOL timeshift --restore --snapshot "$SNAPSHOT" --target-device "$TARGET_DEVICE" --skip-grub --yes
    else
        read -p "Enter GRUB device (e.g., /dev/sda): " GRUB_DEVICE
        $ESCALATION_TOOL timeshift --restore --snapshot "$SNAPSHOT" --target-device "$TARGET_DEVICE" --grub-device "$GRUB_DEVICE" --yes
    fi

    if [ $? -eq 0 ]; then
        echo "Snapshot restored successfully."
    else
        echo "Snapshot restore failed."
    fi
}

# Function to delete a snapshot
delete_snapshot() {
    list_snapshots

    read -p "Enter the snapshot name you want to delete: " SNAPSHOT

    echo "Deleting snapshot $SNAPSHOT..."
    $ESCALATION_TOOL timeshift --delete --snapshot "$SNAPSHOT" --yes

    if [ $? -eq 0 ]; then
        echo "Snapshot deleted successfully."
    else
        echo "Snapshot deletion failed."
    fi
}

# Function to delete all snapshots
delete_all_snapshots() {
    echo "WARNING: This will delete all snapshots!"
    read -p "Are you sure? (yes/no): " CONFIRMATION

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
    read -p "Select an option (1-7): " OPTION

    case $OPTION in
        1) list_snapshots ;;
        2) list_devices ;;
        3) create_snapshot ;;
        4) restore_snapshot ;;
        5) delete_snapshot ;;
        6) delete_all_snapshots ;;
        7) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac

    read -p "Press Enter to continue..."  
done
}

checkEnv
checkEscalationTool
install_timeshift  
main_menu
