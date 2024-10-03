#!/bin/sh -e

. ../common-script.sh

# Function to display available drives and allow the user to select one
select_drive() {
    clear
    printf "%b\n" "Available drives and partitions:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,UUID | grep -v 'loop' # list all non-loop devices
    printf "\n"
    printf "%b\n" "Enter the drive/partition name (e.g., sda1, sdb1): "
    read -r drive_name
    # Check if the input is valid
    if lsblk | grep -q "${drive_name}"; then
        partition="/dev/${drive_name}"
    else
        printf "%b\n" "${RED}Invalid drive/partition name!${RC}"
        exit 1
    fi
}

# Function to get UUID and FSTYPE of the selected drive
get_uuid_fstype() {
    UUID=$("$ESCALATION_TOOL" blkid -s UUID -o value "${partition}")
    FSTYPE=$(lsblk -no FSTYPE "${partition}")
    NAME=$(lsblk -no NAME "${partition}")

    if [ -z "$UUID" ]; then
        printf "%b\n" "${RED}Failed to retrieve the UUID. Exiting.${RC}"
        exit 1
    fi

    if [ -z "$FSTYPE" ]; then
        printf "%b\n" "${RED}Failed to retrieve the filesystem type. Exiting.${RC}"
        exit 1
    fi
}

# Function to create a mount point
create_mount_point() {
    printf "%b\n" "Enter the mount point path (e.g., /mnt/hdd): "
    read -r mount_point
    if [ ! -d "$mount_point" ]; then
        printf "%b\n" "${YELLOW}Mount point doesn't exist. Creating it..${RC}."
        "$ESCALATION_TOOL" mkdir -p "$mount_point"
    else
        printf "%b\n" "${RED}Mount point already exists.${RC}"
    fi
}

# Function to update /etc/fstab with a comment on the first line and the actual entry on the second line
update_fstab() {
    printf "%b\n" "${YELLOW}Adding entry to /etc/fstab...${RC}"
    "$ESCALATION_TOOL" cp /etc/fstab /etc/fstab.bak # Backup fstab

    # Prepare the comment and the fstab entry
    comment="# Mount for /dev/$NAME"
    fstab_entry="UUID=$UUID $mount_point $FSTYPE defaults 0 2"

    # Append the comment and the entry to /etc/fstab
    printf "%b\n" "$comment" | "$ESCALATION_TOOL"  tee -a /etc/fstab > /dev/null
    printf "%b\n" "$fstab_entry" | "$ESCALATION_TOOL"  tee -a /etc/fstab > /dev/null
    printf "%b\n" "" | "$ESCALATION_TOOL" tee -a /etc/fstab > /dev/null

    printf "%b\n" "Entry added to /etc/fstab:"
    printf "%b\n" "$comment"
    printf "%b\n" "$fstab_entry"
}


# Function to mount the drive
mount_drive() {
    printf "%b\n" "Mounting the drive..."
    "$ESCALATION_TOOL"  mount -a
    if mount | grep "$mount_point" > /dev/null; then
        printf "%b\n" "${GREEN}Drive mounted successfully at $mount_point${RC}."
    else
        printf "%b\n" "${RED}Failed to mount the drive.${RC}"
        exit 1
    fi
}

checkEnv
checkEscalationTool
select_drive
get_uuid_fstype
create_mount_point
update_fstab
mount_drive
