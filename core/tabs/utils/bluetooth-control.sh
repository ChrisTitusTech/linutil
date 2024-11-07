#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Function to check Bluez is installed
setupBluetooth() {
    printf "%b\n" "${YELLOW}Installing Bluez...${RC}"
    if ! command_exists bluetoothctl; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm bluez-utils
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add bluez
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y bluez
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Bluez is already installed.${RC}"
    fi

    startService bluetooth
}

# Function to display the main menu
main_menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}Bluetooth Manager${RC}"
        printf "%b\n" "${YELLOW}=================${RC}"
        printf "%b\n" "1. Scan for devices"
        printf "%b\n" "2. Pair with a device"
        printf "%b\n" "3. Connect to a device"
        printf "%b\n" "4. Disconnect from a device"
        printf "%b\n" "5. Remove a device"
        printf "%b\n" "0. Exit"
        printf "%b" "Choose an option: "
        read -r choice

        case $choice in
            1) scan_devices ;;
            2) pair_device ;;
            3) connect_device ;;
            4) disconnect_device ;;
            5) remove_device ;;
            0) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
        esac
    done
}

# Function to scan for devices
scan_devices() {
    clear
    printf "%b\n" "${YELLOW}Scanning for devices...${RC}"
    bluetoothctl --timeout 10 scan on
    devices=$(bluetoothctl devices)
    if [ -z "$devices" ]; then
        printf "%b\n" "${RED}No devices found.${RC}"
    else
        printf "%b\n" "${GREEN}Devices found:${RC}"
        printf "%b\n" "$devices"
    fi
    printf "%b" "Press any key to return to the main menu..."
    read -r dummy
}

# Function to prompt for MAC address using numbers
prompt_for_mac() {
    action=$1
    command=$2
    prompt_msg=$3
    success_msg=$4
    failure_msg=$5

    while true; do
        clear
        devices=$(bluetoothctl devices)
        if [ -z "$devices" ]; then
            printf "%b\n" "${RED}No devices available. Please scan for devices first.${RC}"
            printf "%b" "Press any key to return to the main menu..."
            read -r dummy
            return
        fi

        # Display devices with numbers
        device_list=$(echo "$devices" | tr '\n' '\n')
        i=1
        echo "$device_list" | while IFS= read -r device; do
            printf "%d. %s\n" "$i" "$device"
            i=$((i + 1))
        done
        printf "%b\n" "0. Exit to main menu"
        printf "%b\n" "$prompt_msg"
        read -r choice

        # Validate the choice
        if echo "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -le "$((i - 1))" ] && [ "$choice" -gt 0 ]; then
            device=$(echo "$device_list" | sed -n "${choice}p")
            mac=$(echo "$device" | awk '{print $2}')
            if bluetoothctl info "$mac" > /dev/null 2>&1; then
                bluetoothctl "$command" "$mac" && {
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                    break
                } || {
                    printf "%b\n" "${RED}$failure_msg${RC}"
                }
            else
                printf "%b\n" "${RED}Invalid MAC address. Please try again.${RC}"
            fi
        elif [ "$choice" -eq 0 ]; then
            return
        else
            printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
        fi
    done
    printf "%b" "Press any key to return to the main menu..."
    read -r dummy
}

# Function to pair with a device
pair_device() {
    prompt_for_mac "pair" "pair" "Enter the number of the device to pair: " "Pairing with device completed." "Failed to pair with device."
}

# Function to connect to a device
connect_device() {
    prompt_for_mac "connect" "connect" "Enter the number of the device to connect: " "Connecting to device completed." "Failed to connect to device."
}

# Function to disconnect from a device
disconnect_device() {
    prompt_for_mac "disconnect" "disconnect" "Enter the number of the device to disconnect: " "Disconnecting from device completed." "Failed to disconnect from device."
}

# Function to remove a device
remove_device() {
    prompt_for_mac "remove" "remove" "Enter the number of the device to remove: " "Removing device completed." "Failed to remove device."
}

# Initialize
checkEnv
checkEscalationTool
setupBluetooth
main_menu
