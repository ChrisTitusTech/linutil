#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

# Function to check if NetworkManager is installed
setupNetworkManager() {
    printf "%b\n" "${YELLOW}Installing NetworkManager...${RC}"
    if ! command_exists nmcli; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm networkmanager
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y NetworkManager-1
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add networkmanager-wifi iwd
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy NetworkManager iwd
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y network-manager
                ;;
        esac
    else
        printf "%b\n" "${YELLOW}NetworkManager is already installed.${RC}"
    fi
    
    # Check if NetworkManager service is running
    if ! isServiceActive NetworkManager; then
        printf "%b\n" "${YELLOW}NetworkManager service is not running. Starting it now...${RC}"
        startAndEnableService NetworkManager
    else 
        printf "%b\n" "${GREEN}NetworkManager service started successfully.${RC}"
    fi
}

# Function to display the main menu
main_menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}WiFi Manager${RC}"
        printf "%b\n" "${YELLOW}============${RC}"
        printf "%b\n" "1. Turn WiFi On"
        printf "%b\n" "2. Turn WiFi Off"
        printf "%b\n" "3. Scan for WiFi networks"
        printf "%b\n" "4. Connect to a WiFi network"
        printf "%b\n" "5. Disconnect from a WiFi network"
        printf "%b\n" "6. Remove a WiFi connection"
        printf "%b\n" "0. Exit"
        printf "%b" "Choose an option: "
        read -r choice

        case $choice in
            1) wifi_on ;;
            2) wifi_off ;;
            3) scan_networks ;;
            4) connect_network ;;
            5) disconnect_network ;;
            6) remove_network ;;
            0) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
        esac
    done
}

# Function to scan for WiFi networks
scan_networks() {
    clear
    printf "%b\n" "${YELLOW}Scanning for WiFi networks...${RC}"
    networks=$(nmcli -t -f SSID,BSSID,SIGNAL dev wifi list | awk -F: '!seen[$1]++' | head -n 10)
    if [ -z "$networks" ]; then
        printf "%b\n" "${RED}No networks found.${RC}"
    else
        printf "%b\n" "${GREEN}Top 10 Networks found:${RC}"
        echo "$networks" | awk -F: '{printf("%d. SSID: %-25s \n", NR, $1)}'
    fi
    printf "%b\n" "Press any key to return to the main menu..."
    read -r _
}

# Function to turn WiFi on
wifi_on() {
    clear
    printf "%b\n" "${YELLOW}Turning WiFi on...${RC}"
    if "$(nmcli radio wifi on)"; then
        printf "%b\n" "${GREEN}WiFi is now turned on.${RC}"
    else
        printf "%b\n" "${RED}Failed to turn on WiFi.${RC}"
    fi
    printf "%b\n" "Press any key to return to the main menu..."
    read -r _
}

# Function to turn WiFi off
wifi_off() {
    clear
    printf "%b\n" "${YELLOW}Turning WiFi off...${RC}"
    if "$(nmcli radio wifi off)"; then
        printf "%b\n" "${GREEN}WiFi is now turned off.${RC}"
    else
        printf "%b\n" "${RED}Failed to turn off WiFi.${RC}"
    fi
    printf "%b\n" "Press any key to return to the main menu..."
    read -r _
}

# Function to prompt for WiFi network selection
build_network_list() {
    action=$1

    case "$action" in
        connect)
            nmcli -t -f SSID dev wifi list | sed '/^$/d' | awk '!seen[$0]++'
            ;;
        disconnect | remove)
            nmcli -t -f NAME,TYPE connection show | awk -F: '$2 == "802-11-wireless" && $1 != "" { print $1 }' | awk '!seen[$0]++'
            ;;
        *)
            return 1
            ;;
    esac
}

select_network_index() {
    list_file=$1
    prompt_msg=$2
    page_size=10
    total=$(wc -l < "$list_file")
    [ "$total" -eq 0 ] && return 1

    page=1
    pages=$(( (total + page_size - 1) / page_size ))

    while true; do
        clear
        start=$(( (page - 1) * page_size + 1 ))
        end=$(( page * page_size ))
        [ "$end" -gt "$total" ] && end=$total

        printf "%b\n" "${YELLOW}Available Networks (page ${page}/${pages})${RC}"
        nl -w1 -s'. ' "$list_file" | sed -n "${start},${end}p"
        printf "%b\n" "n. Next page    p. Previous page    r. Refresh list    0. Exit to main menu"
        printf "%b" "$prompt_msg"
        read -r choice

        case "$choice" in
            0) return 1 ;;
            n | N)
                [ "$page" -lt "$pages" ] && page=$((page + 1))
                ;;
            p | P)
                [ "$page" -gt 1 ] && page=$((page - 1))
                ;;
            r | R) return 2 ;;
            *)
                case "$choice" in
                    '' | *[!0-9]*)
                        printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
                        ;;
                    *)
                        if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
                            SELECTED_NETWORK_INDEX=$choice
                            return 0
                        fi
                        printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
                        ;;
                esac
                ;;
        esac

        printf "%b\n" "Press any key to continue..."
        read -r _
    done
}

prompt_for_network() {
    action=$1
    prompt_msg=$2
    success_msg=$3
    failure_msg=$4
    temp_file=$(mktemp)

    while true; do
        clear
        networks=$(build_network_list "$action")
        if [ -z "$networks" ]; then
            printf "%b\n" "${RED}No networks available. Please scan for networks first.${RC}"
            printf "%b\n" "Press any key to return to the main menu..."
            read -r _
            rm -f "$temp_file"
            return
        fi

        echo "$networks" > "$temp_file"

        if select_network_index "$temp_file" "$prompt_msg"; then
            selection_status=0
        else
            selection_status=$?
        fi
        if [ "$selection_status" -eq 1 ]; then
            rm -f "$temp_file"
            return
        fi
        if [ "$selection_status" -eq 2 ]; then
            continue
        fi

        ssid=$(sed -n "${SELECTED_NETWORK_INDEX}p" "$temp_file")
        case "$action" in
            connect)
                printf "%b" "Enter password for SSID: $ssid "
                read -r password
                printf "\n"
                if [ -n "$password" ]; then
                    if nmcli dev wifi connect "$ssid" password "$password"; then
                        printf "%b\n" "${GREEN}$success_msg${RC}"
                    else
                        printf "%b\n" "${RED}$failure_msg${RC}"
                    fi
                elif nmcli dev wifi connect "$ssid"; then
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                else
                    printf "%b\n" "${RED}$failure_msg${RC}"
                fi
                ;;
            disconnect)
                if nmcli connection down "$ssid"; then
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                else
                    printf "%b\n" "${RED}$failure_msg${RC}"
                fi
                ;;
            remove)
                if nmcli connection delete "$ssid"; then
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                else
                    printf "%b\n" "${RED}$failure_msg${RC}"
                fi
                ;;
        esac

        printf "%b\n" "Press any key to return to the selection menu..."
        read -r _
    done

    rm -f "$temp_file"
}

# Function to connect to a WiFi network
connect_network() {
    prompt_for_network "connect" "Enter the number of the network to connect: " "Connected to the network successfully." "Failed to connect to the network."
}

# Function to disconnect from a WiFi network
disconnect_network() {
    prompt_for_network "disconnect" "Enter the number of the network to disconnect: " "Disconnected from the network successfully." "Failed to disconnect from the network."
}

# Function to remove a WiFi connection
remove_network() {
    prompt_for_network "remove" "Enter the number of the network to remove: " "Network removed successfully." "Failed to remove the network."
}

# Initialize
checkEnv
checkEscalationTool
setupNetworkManager
main_menu
