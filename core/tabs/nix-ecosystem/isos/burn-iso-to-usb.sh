#!/bin/sh -e

. ../../common-script.sh

burnISO() {
    printf "%b" "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  BURN ISO TO USB                                                               ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "%b\n" "${RC}"

    # List available ISOs in Downloads
    ISO_DIR="${HOME}/Downloads"
    
    printf "%b\n" "${CYAN}Scanning for ISO files in ${ISO_DIR}...${RC}"
    printf "%b\n" ""
    
    if [ -d "$ISO_DIR" ]; then
        iso_files=$(find "$ISO_DIR" -maxdepth 1 -name "*.iso" -type f 2>/dev/null | sort)
    else
        iso_files=""
    fi

    if [ -z "$iso_files" ]; then
        printf "%b\n" "${YELLOW}No ISO files found in ${ISO_DIR}${RC}"
        printf "%b\n" ""
        printf "%b" "${YELLOW}Enter full path to ISO file: ${RC}"
        read -r ISO_PATH
    else
        printf "%b\n" "${CYAN}Available ISOs:${RC}"
        i=1
        echo "$iso_files" | while IFS= read -r iso; do
            name=$(basename "$iso")
            size=$(du -h "$iso" 2>/dev/null | cut -f1)
            printf "%b\n" "  ${i}) ${name} (${size})"
            i=$((i + 1))
        done
        printf "%b\n" ""
        printf "%b" "${YELLOW}Select ISO number (or enter full path): ${RC}"
        read -r iso_choice
        
        if printf "%s" "$iso_choice" | grep -qE '^[0-9]+$'; then
            ISO_PATH=$(echo "$iso_files" | sed -n "${iso_choice}p")
        else
            ISO_PATH="$iso_choice"
        fi
    fi

    if [ ! -f "$ISO_PATH" ]; then
        printf "%b\n" "${RED}ISO file not found: ${ISO_PATH}${RC}"
        return 1
    fi

    printf "%b\n" ""
    printf "%b\n" "${GREEN}Selected: $(basename "$ISO_PATH")${RC}"
    printf "%b\n" ""

    # List USB devices
    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════════════════════════
  AVAILABLE BLOCK DEVICES
══════════════════════════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
    
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E "^(NAME|sd|nvme)" || lsblk -d -o NAME,SIZE,MODEL
    
    printf "%b\n" ""
    printf "%b\n" "${RED}⚠️  WARNING: This will ERASE ALL DATA on the selected device!${RC}"
    printf "%b\n" "${RED}⚠️  Make sure you select the correct USB drive!${RC}"
    printf "%b\n" ""
    printf "%b\n" "${YELLOW}Tips to identify your USB:${RC}"
    printf "%b\n" "  • Run 'lsblk' before and after inserting USB"
    printf "%b\n" "  • USB drives are usually /dev/sdb, /dev/sdc, etc."
    printf "%b\n" "  • Check the SIZE column matches your USB capacity"
    printf "%b\n" "  • TRAN column shows 'usb' for USB devices"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Enter device (e.g., sdb — NOT sdb1): ${RC}"
    read -r device

    # Validate input
    if [ -z "$device" ]; then
        printf "%b\n" "${RED}No device specified. Aborting.${RC}"
        return 1
    fi

    # Strip /dev/ if provided
    device=$(printf "%s" "$device" | sed 's|^/dev/||')
    DEVICE_PATH="/dev/${device}"

    # Safety checks
    if [ ! -b "$DEVICE_PATH" ]; then
        printf "%b\n" "${RED}Device ${DEVICE_PATH} not found or not a block device.${RC}"
        return 1
    fi

    # Prevent writing to partitions
    if printf "%s" "$device" | grep -qE '[0-9]$'; then
        printf "%b\n" "${RED}Please specify the whole disk (e.g., sdb), not a partition (sdb1).${RC}"
        return 1
    fi

    # Prevent writing to system disk
    root_disk=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | sed 's|/dev/||')
    if [ "$device" = "$root_disk" ]; then
        printf "%b\n" "${RED}Cannot write to system disk! Aborting.${RC}"
        return 1
    fi

    printf "%b\n" ""
    printf "%b\n" "${YELLOW}You are about to write:${RC}"
    printf "%b\n" "  ISO:    $(basename "$ISO_PATH")"
    printf "%b\n" "  Device: ${DEVICE_PATH}"
    printf "%b\n" ""
    printf "%b" "${RED}Type 'yes' to confirm (this will ERASE the device): ${RC}"
    read -r confirm

    if [ "$confirm" != "yes" ]; then
        printf "%b\n" "${YELLOW}Aborted.${RC}"
        return 0
    fi

    # Unmount any mounted partitions
    printf "%b\n" "${YELLOW}Unmounting ${DEVICE_PATH} partitions...${RC}"
    "$ESCALATION_TOOL" umount "${DEVICE_PATH}"* 2>/dev/null || true

    # Write ISO
    printf "%b\n" ""
    printf "%b\n" "${CYAN}Writing ISO to ${DEVICE_PATH}...${RC}"
    printf "%b\n" "${YELLOW}This may take several minutes depending on ISO size and USB speed.${RC}"
    printf "%b\n" ""

    "$ESCALATION_TOOL" dd if="$ISO_PATH" of="$DEVICE_PATH" bs=4M conv=fsync status=progress

    printf "%b\n" ""
    printf "%b\n" "${YELLOW}Syncing...${RC}"
    "$ESCALATION_TOOL" sync

    printf "%b\n" ""
    printf "%b\n" "${GREEN}✓ ISO written successfully!${RC}"
    printf "%b\n" ""

    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════════════════════════
  NEXT STEPS
══════════════════════════════════════════════════════════════════════════════════
  1. Safely eject the USB drive:
       sudo eject /dev/sdX
  
  2. Insert USB into target machine
  
  3. Reboot and enter BIOS/UEFI boot menu:
       Common keys: F12 (Dell/Lenovo), F8/Esc (ASUS), F9 (HP), F11 (MSI)
  
  4. Select USB as boot device
══════════════════════════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
}

checkArch
checkEscalationTool
burnISO
