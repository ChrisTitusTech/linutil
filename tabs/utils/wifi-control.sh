#!/bin/sh -e

. ../common-script.sh

# Function to check if NetworkManager is installed
setupNetworkManager() {
    printf "%b\n" "${YELLOW}Installing NetworkManager...${RC}"
    if ! command_exists nmcli; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --noconfirm networkmanager
                ;;
            dnf)
                $ESCALATION_TOOL "${PACKAGER}" install -y NetworkManager-1
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y network-manager
                ;;
        esac
    else
        printf "%b\n" "${YELLOW}NetworkManager is already installed.${RC}"
    fi
    
    # Check if NetworkManager service is running
    if ! systemctl is-active --quiet NetworkManager; then
        printf "%b\n" "${YELLOW}NetworkManager service is not running. Starting it now...${RC}"
        $ESCALATION_TOOL systemctl start NetworkManager
        
        if systemctl is-active --quiet NetworkManager; then
            printf "%b\n" "${GREEN}NetworkManager service started successfully.${RC}"
        fi
    fi
}

# Function to display the main menu
main_menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}WiFi Manager${RC}"
        printf "%b\n" "${YELLOW}============${RC}"
        echo "1. Turn WiFi On"
        echo "2. Turn WiFi Off"
        echo "3. Scan for WiFi networks"
        echo "4. Connect to a WiFi network"
        echo "5. Disconnect from a WiFi network"
        echo "6. Remove a WiFi connection"
        echo "0. Exit"
        echo -n "Choose an option: "
        read choice

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
    networks=$(nmcli -t -f SSID,BSSID,SIGNAL dev wifi list | head -n 10)
    if [ -z "$networks" ]; then
        printf "%b\n" "${RED}No networks found.${RC}"
    else
        printf "%b\n" "${GREEN}Top 10 Networks found:${RC}"
        echo "$networks" | sed 's/\\//g' | awk -F: '{printf("%d. SSID: %-25s \n", NR, $1)}'
    fi
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to turn WiFi on
wifi_on() {
    clear
    printf "%b\n" "${YELLOW}Turning WiFi on...${RC}"
    nmcli radio wifi on && {
        printf "%b\n" "${GREEN}WiFi is now turned on.${RC}"
    } || {
        printf "%b\n" "${RED}Failed to turn on WiFi.${RC}"
    }
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to turn WiFi off
wifi_off() {
    clear
    printf "%b\n" "${YELLOW}Turning WiFi off...${RC}"
    nmcli radio wifi off && {
        printf "%b\n" "${GREEN}WiFi is now turned off.${RC}"
    } || {
        printf "%b\n" "${RED}Failed to turn off WiFi.${RC}"
    }
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to prompt for WiFi network selection
prompt_for_network() {
    action=$1
    prompt_msg=$2
    success_msg=$3
    failure_msg=$4

    while true; do
        clear
        networks=$(nmcli -t -f SSID dev wifi list | head -n 10)
        if [ -z "$networks" ]; then
            printf "%b\n" "${RED}No networks available. Please scan for networks first.${RC}"
            echo "Press any key to return to the main menu..."
            read -n 1
            return
        fi
        
        # Display networks with numbers
        i=1
        echo "$networks" | while IFS= read -r network; do
            ssid=$(echo "$network" | awk -F: '{print $1}')
            echo "$i. SSID: $ssid"
            i=$((i + 1))
        done
        echo "0. Exit to main menu"
        echo -n "$prompt_msg"
        read choice

        # Validate the choice
        if echo "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -le "$((i - 1))" ] && [ "$choice" -gt 0 ]; then
            network=$(echo "$networks" | sed -n "${choice}p")
            ssid=$(echo "$network" | awk -F: '{print $1}')
            if [ "$action" = "connect" ]; then
                echo -n "Enter password for SSID $ssid: "
                read -s password
                echo
                nmcli dev wifi connect "$ssid" password "$password" && {
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                    break
                } || {
                    printf "%b\n" "${RED}$failure_msg${RC}"
                }
            elif [ "$action" = "disconnect" ]; then
                nmcli connection down "$ssid" && {
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                    break
                } || {
                    printf "%b\n" "${RED}$failure_msg${RC}"
                }
            elif [ "$action" = "remove" ]; then
                nmcli connection delete "$ssid" && {
                    printf "%b\n" "${GREEN}$success_msg${RC}"
                    break
                } || {
                    printf "%b\n" "${RED}$failure_msg${RC}"
                }
            fi
        elif [ "$choice" -eq 0 ]; then
            return
        else
            printf "%b\n" "${RED}Invalid choice. Please try again.${RC}"
        fi
    done
    echo "Press any key to return to the main menu..."
    read -n 1
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
setupNetworkManager
main_menu
