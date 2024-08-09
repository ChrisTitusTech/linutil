#!/bin/bash

# Function to display colored text
colored_echo() {
    local color=$1
    local text=$2
    case $color in
        red) echo -e "\033[31m$text\033[0m" ;;
        green) echo -e "\033[32m$text\033[0m" ;;
        yellow) echo -e "\033[33m$text\033[0m" ;;
        blue) echo -e "\033[34m$text\033[0m" ;;
        *) echo "$text" ;;
    esac
}

# Function to display the main menu
main_menu() {
    while true; do
        clear
        colored_echo blue "Bluetooth Manager"
        colored_echo blue "================="
        echo "1. Scan for devices"
        echo "2. Pair with a device"
        echo "3. Connect to a device"
        echo "4. Disconnect from a device"
        echo "5. Remove a device"
        echo "0. Exit"
        echo -n "Choose an option: "
        read -e choice

        case $choice in
            1) scan_devices ;;
            2) pair_device ;;
            3) connect_device ;;
            4) disconnect_device ;;
            5) remove_device ;;
            0) exit 0 ;;
            *) colored_echo red "Invalid option. Please try again." ;;
        esac
    done
}

# Function to scan for devices
scan_devices() {
    clear
    colored_echo yellow "Scanning for devices..."
    bluetoothctl --timeout 10 scan on
    devices=$(bluetoothctl devices)
    if [ -z "$devices" ]; then
        colored_echo red "No devices found."
    else
        colored_echo green "Devices found:"
        echo "$devices"
    fi
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to prompt for MAC address using numbers
prompt_for_mac() {
    local action=$1
    local command=$2
    local prompt_msg=$3
    local success_msg=$4
    local failure_msg=$5

    while true; do
        clear
        devices=$(bluetoothctl devices)
        if [ -z "$devices" ]; then
            colored_echo red "No devices available. Please scan for devices first."
            echo "Press any key to return to the main menu..."
            read -n 1
            return
        fi

        # Display devices with numbers
        IFS=$'\n' read -rd '' -a device_list <<<"$devices"
        for i in "${!device_list[@]}"; do
            echo "$((i+1)). ${device_list[$i]}"
        done
        echo "0. Exit to main menu"
        echo -n "$prompt_msg"
        read -e choice

        # Validate the choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -le "${#device_list[@]}" ] && [ "$choice" -gt 0 ]; then
            device=${device_list[$((choice-1))]}
            mac=$(echo "$device" | awk '{print $2}')
            if bluetoothctl info "$mac" > /dev/null 2>&1; then
                bluetoothctl $command "$mac" && {
                    colored_echo green "$success_msg"
                    break
                } || {
                    colored_echo red "$failure_msg"
                }
            else
                colored_echo red "Invalid MAC address. Please try again."
            fi
        elif [ "$choice" -eq 0 ]; then
            return
        else
            colored_echo red "Invalid choice. Please try again."
        fi
    done
    echo "Press any key to return to the main menu..."
    read -n 1
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
main_menu