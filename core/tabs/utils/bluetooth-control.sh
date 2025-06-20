#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

setupBluetooth() {
    printf "%b\n" "${YELLOW}Installing Bluez...${RC}"
    if ! command_exists bluetoothctl; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm bluez bluez-utils
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add bluez
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy bluez
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y bluez
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Bluez is already installed.${RC}"
    fi

    # Set service name based on distribution
    SERVICE_NAME="bluetooth"
    if [ "$PACKAGER" = "xbps-install" ]; then
        SERVICE_NAME="bluetoothd"
    fi
    
    startAndEnableService "$SERVICE_NAME"
}

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
    read -r _
}

prompt_for_mac() {
    command=$1
    prompt_msg=$2
    success_msg=$3
    failure_msg=$4

    while true; do
        clear
        devices=$(bluetoothctl devices)
        if [ -z "$devices" ]; then
            printf "%b\n" "${RED}No devices available. Please scan for devices first.${RC}"
            printf "%b" "Press any key to return to the main menu..."
            read -r _
            return
        fi

        # Display devices with numbers
        i=1
        echo "$devices" | while IFS= read -r device; do
            printf "%d. %s\n" "$i" "$device"
            i=$((i + 1))
        done
        printf "%b\n" "0. Exit to main menu"
        printf "%b" "$prompt_msg"
        read -r choice

        count=$(printf "%b" "$devices" | wc -l)
        count=$((count + 1))

        if echo "$choice" | grep -qE '^[0-9]+$' && [ -n "$choice" ] && [ "$choice" -le "$count" ] && [ "$choice" -gt 0 ]; then
            device=$(echo "$devices" | sed -n "${choice}p")
            mac=$(echo "$device" | awk '{print $2}')
            if bluetoothctl info "$mac" > /dev/null 2>&1; then
                if bluetoothctl "$command" "$mac"; then
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                    break
                else
                    printf "%b\n" "${RED}$failure_msg${RC}"
                    read -r _
                fi
            else
                printf "%b\n" "${RED}Invalid MAC address. Please try again.${RC}"
                read -r _
            fi
        elif [ "$choice" -eq 0 ]; then
            return
        else
            printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
            read -r _
        fi
    done
}

pair_device() {
    prompt_for_mac "pair" "Enter the number of the device to pair: " "Pairing with device completed." "Failed to pair with device."
}

connect_device() {
    prompt_for_mac "connect" "Enter the number of the device to connect: " "Connecting to device completed." "Failed to connect to device."
}

disconnect_device() {
    prompt_for_mac "disconnect" "Enter the number of the device to disconnect: " "Disconnecting from device completed." "Failed to disconnect from device."
}

remove_device() {
    prompt_for_mac "remove" "Enter the number of the device to remove: " "Removing device completed." "Failed to remove device."
}

checkEnv
checkEscalationTool
setupBluetooth
main_menu
