@@ -0,0 +1,168 @@
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
        colored_echo blue "WiFi Manager"
        colored_echo blue "============"
        echo "1. Turn WiFi On"
        echo "2. Turn WiFi Off"
        echo "3. Scan for WiFi networks"
        echo "4. Connect to a WiFi network"
        echo "5. Disconnect from a WiFi network"
        echo "6. Remove a WiFi connection"
        echo "0. Exit"
        echo -n "Choose an option: "
        read -e choice

        case $choice in
            1) wifi_on ;;
            2) wifi_off ;;
            3) scan_networks ;;
            4) connect_network ;;
            5) disconnect_network ;;
            6) remove_network ;;
            0) exit 0 ;;
            *) colored_echo red "Invalid option. Please try again." ;;
        esac
    done
}

# Function to scan for WiFi networks
scan_networks() {
    clear
    colored_echo yellow "Scanning for WiFi networks..."
    networks=$(nmcli -t -f SSID,BSSID,SIGNAL dev wifi list | head -n 10)
    if [ -z "$networks" ]; then
        colored_echo red "No networks found."
    else
        colored_echo green "Top 10 Networks found:"
        echo "$networks" | sed 's/\\//g' | awk -F: '{printf("%d. SSID: %-25s \n", NR, $1)}'
    fi
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to turn WiFi on
wifi_on() {
    clear
    colored_echo yellow "Turning WiFi on..."
    nmcli radio wifi on && {
        colored_echo green "WiFi is now turned on."
    } || {
        colored_echo red "Failed to turn on WiFi."
    }
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to turn WiFi off
wifi_off() {
    clear
    colored_echo yellow "Turning WiFi off..."
    nmcli radio wifi off && {
        colored_echo green "WiFi is now turned off."
    } || {
        colored_echo red "Failed to turn off WiFi."
    }
    echo "Press any key to return to the main menu..."
    read -n 1
}

# Function to prompt for WiFi network selection
prompt_for_network() {
    local action=$1
    local prompt_msg=$2
    local success_msg=$3
    local failure_msg=$4

    while true; do
        clear
        networks=$(nmcli -t -f SSID dev wifi list | head -n 10)
        if [ -z "$networks" ]; then
            colored_echo red "No networks available. Please scan for networks first."
            echo "Press any key to return to the main menu..."
            read -n 1
            return
        fi

        # Display networks with numbers
        IFS=$'\n' read -rd '' -a network_list <<<"$networks"
        for i in "${!network_list[@]}"; do
            ssid=$(echo "${network_list[$i]}" | awk -F: '{print $1}')
            echo "$((i+1)). SSID: $ssid"
        done
        echo "0. Exit to main menu"
        echo -n "$prompt_msg"
        read -e choice

        # Validate the choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -le "${#network_list[@]}" ] && [ "$choice" -gt 0 ]; then
            network=${network_list[$((choice-1))]}
            ssid=$(echo "$network" | awk -F: '{print $1}')
            if [ "$action" == "connect" ]; then
                echo -n "Enter password for SSID $ssid: "
                read -s password
                echo
                nmcli dev wifi connect "$ssid" password "$password" && {
                    colored_echo green "$success_msg"
                    break
                } || {
                    colored_echo red "$failure_msg"
                }
            elif [ "$action" == "disconnect" ]; then
                nmcli connection down "$ssid" && {
                    colored_echo green "$success_msg"
                    break
                } || {
                    colored_echo red "$failure_msg"
                }
            elif [ "$action" == "remove" ]; then
                nmcli connection delete "$ssid" && {
                    colored_echo green "$success_msg"
                    break
                } || {
                    colored_echo red "$failure_msg"
                }
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
main_menu