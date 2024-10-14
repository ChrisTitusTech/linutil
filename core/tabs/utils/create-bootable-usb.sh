#!/bin/sh -e

. ../common-script.sh  

# Function to display usage instructions
usage() {
    printf "%b\n" "${RED} Usage: $0 ${RC}"
    printf "%b\n" "No arguments needed. The script will prompt for ISO path and USB device."
    exit 1
}

# Function to display all available block devices
list_devices() {
    printf "%b\n" "${YELLOW} Available devices and partitions: ${RC}"
    printf "\n"
    elevated_execution lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL
    printf "\n"
}

# Function to fetch the latest Arch Linux ISO
fetch_arch_latest_iso() {
    ARCH_BASE_URL="https://archive.archlinux.org/iso/"
    ARCH_LATEST=$(curl -s "$ARCH_BASE_URL" | grep -oP '(?<=href=")[0-9]{4}\.[0-9]{2}\.[0-9]{2}(?=/)' | sort -V | tail -1)
    ARCH_URL="${ARCH_BASE_URL}${ARCH_LATEST}/archlinux-${ARCH_LATEST}-x86_64.iso"
    printf "%b\n" "${GREEN} Selected Arch Linux (latest) ISO URL: ${RC} $ARCH_URL"
}

# Function to fetch older Arch Linux ISOs and display in a table format
fetch_arch_older_isos() {
    ARCH_BASE_URL="https://archive.archlinux.org/iso/"
    ARCH_VERSIONS=$(curl -s "$ARCH_BASE_URL" | grep -oP '(?<=href=")[0-9]{4}\.[0-9]{2}\.[0-9]{2}(?=/)' | sort -V)

    # Filter versions to include only those from 2017-04-01 and later
    MIN_DATE="2017.04.01"
    ARCH_VERSIONS=$(echo "$ARCH_VERSIONS" | awk -v min_date="$MIN_DATE" '$0 >= min_date')

    if [ -z "$ARCH_VERSIONS" ]; then
        printf "%b\n" "${RED}No Arch Linux versions found from ${MIN_DATE} onwards.${RC}"
        exit 1
    fi

    printf "%b\n" "${YELLOW}Available Arch Linux versions from ${MIN_DATE} onwards:${RC}"
    
    COUNTER=1
    ROW_ITEMS=6  # Number of versions to show per row
    for VERSION in $ARCH_VERSIONS; do
        printf "%-5s${YELLOW}%-15s ${RC}" "$COUNTER)" "$VERSION"
        
        if [ $(( COUNTER % ROW_ITEMS )) -eq 0 ]; then
            printf "\n"  # New line after every 6 versions
        fi
        
        COUNTER=$((COUNTER + 1))
    done
    printf "\n"  # New line after the last row
    printf "%b" "Select an Arch Linux version (1-$((COUNTER - 1))): "
    read -r ARCH_OPTION
    ARCH_DIR=$(echo "$ARCH_VERSIONS" | sed -n "${ARCH_OPTION}p")
    ARCH_URL="${ARCH_BASE_URL}${ARCH_DIR}/archlinux-${ARCH_DIR}-x86_64.iso"
    printf "%b\n" "${GREEN}Selected Arch Linux (older) ISO URL: $ARCH_URL${RC}"
}

# Function to fetch the latest Debian Linux ISO
fetch_debian_latest_iso() {
    DEBIAN_URL=$(curl -s https://www.debian.org/distrib/netinst | grep -oP '(?<=href=")[^"]+debian-[0-9.]+-amd64-netinst.iso(?=")' | head -1)
    printf "%b\n" "${GREEN} Selected Debian Linux (latest) ISO URL: ${RC} $DEBIAN_URL"
}

# Function to ask whether to use local or online ISO
choose_iso_source() {
    printf "%b\n" "${YELLOW} Do you want to use a local ISO or download online? ${RC}"
    printf "1) Download online\n"
    printf "2) Use local ISO\n"
    printf "\n"
    printf "%b" "Select option (1-2): "
    read -r ISO_SOURCE_OPTION

    case $ISO_SOURCE_OPTION in
        1)
            fetch_iso_urls  # Call the function to fetch online ISO URLs
            ;;
        2)
            printf "Enter the path to the already downloaded ISO file: "
            read -r ISO_PATH
            if [ ! -f "$ISO_PATH" ]; then
                printf "%b\n" "${RED} ISO file not found: $ISO_PATH ${RC}"
                exit 1
            fi
            ;;
        *)
            printf "%b\n" "${RED}Invalid option selected. ${RC}"
            exit 1
            ;;
    esac
}

# Function to fetch ISO URLs
fetch_iso_urls() {
    clear
    printf "%b\n" "${YELLOW}Available ISOs for download:${RC}"
    printf "%b\n" "1) Arch Linux (latest)"
    printf "%b\n" "2) Arch Linux (older versions)"
    printf "%b\n" "3) Debian Linux (latest)"
    printf "\n"
    printf "%b" "Select the ISO you want to download (1-3): "
    read -r ISO_OPTION

    case $ISO_OPTION in
        1)
            fetch_arch_latest_iso
            ISO_URL=$ARCH_URL
            ;;
        2)
            fetch_arch_older_isos
            ISO_URL=$ARCH_URL
            ;;
        3)
            fetch_debian_latest_iso
            ISO_URL=$DEBIAN_URL
            ;;
        *)
            printf "%b\n" "${RED}Invalid option selected.${RC}"
            exit 1
            ;;
    esac

    ISO_PATH=$(basename "$ISO_URL")
    printf "%b\n" "${YELLOW}Downloading ISO...${RC}"
    curl -L -o "$ISO_PATH" "$ISO_URL"
    if [ $? -ne 0 ]; then
        printf "%b\n" "${RED}Failed to download the ISO file.${RC}"
        exit 1
    fi
}

write_iso(){  
    clear

     # Ask whether to use a local or online ISO
    choose_iso_source

    clear
    # Display all available devices
    list_devices

    # Prompt user for USB device
    printf "%b" "Enter the USB device (e.g. /dev/sdX): "
    read -r USB_DEVICE

    # Verify that the USB device exists
    if [ ! -b "$USB_DEVICE" ]; then
        printf "%b\n" "${RED}USB device not found: $USB_DEVICE${RC}"
        exit 1
    fi

    # Confirm the device selection with the user
    printf "%b" "${RED}WARNING: This will erase all data on ${USB_DEVICE}. Are you sure you want to continue? (y/N): ${RC}"
    read -r CONFIRMATION

    if [ "$CONFIRMATION" != "yes" ]; then
        printf "%b\n" "${YELLOW}Operation cancelled.${RC}"
        exit 1
    fi

    # Display progress and create the bootable USB drive
    printf "%b\n" "${YELLOW}Creating bootable USB drive...${RC}"
    if ! elevated_execution dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress oflag=sync; then
        printf "%b\n" "${RED}Failed to create bootable USB drive${RC}"
        exit 1
    fi

    # Sync to ensure all data is written
    if ! elevated_execution sync; then
        printf "%b\n" "${RED}Failed to sync data${RC}"                              
        exit 1
    fi

    printf "%b\n" "${GREEN}Bootable USB drive created successfully!${RC}"

    # Eject the USB device
    printf "%b\n" "${YELLOW}Ejecting ${USB_DEVICE}...${RC}"
    if ! elevated_execution umount "${USB_DEVICE}"* 2>/dev/null; then
        printf "%b\n" "${RED}Failed to unmount ${USB_DEVICE}${RC}"
    fi
    if ! elevated_execution eject "$USB_DEVICE"; then
        printf "%b\n" "${RED}Failed to eject ${USB_DEVICE}${RC}"
    fi

    printf "%b\n" "${GREEN}You can safely remove your USB drive. Reinsert the drive to be detected.${RC}"
}

checkEnv
checkEscalationTool
write_iso