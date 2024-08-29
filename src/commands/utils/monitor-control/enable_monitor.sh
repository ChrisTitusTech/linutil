#!/bin/bash
source ./utility_functions.sh

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'

# Function to enable a monitor
enable_monitor() {
    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -d '' -a monitor_array <<<"$monitor_list"

    clear
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${BLUE}  Enable Monitor${RESET}"
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${YELLOW}Choose a monitor to enable:${RESET}"
    for i in "${!monitor_array[@]}"; do
        echo -e "$((i + 1)). ${CYAN}${monitor_array[i]}${RESET}"
    done

    read -p "Enter the number of the monitor: " monitor_choice

    if ! [[ "$monitor_choice" =~ ^[0-9]+$ ]] || (( monitor_choice < 1 )) || (( monitor_choice > ${#monitor_array[@]} )); then
        echo -e "${RED}Invalid selection.${RESET}"
        return
    fi

    monitor_name="${monitor_array[monitor_choice - 1]}"

    if confirm_action "Enable ${CYAN}$monitor_name${RESET}?"; then
        echo -e "${GREEN}Enabling $monitor_name${RESET}"
        execute_command "xrandr --output $monitor_name --auto"
        echo -e "${GREEN}Monitor $monitor_name enabled successfully.${RESET}"
    else
        echo -e "${RED}Action canceled.${RESET}"
    fi
}

# Function to prompt for confirmation
confirm_action() {
    local action="$1"
    echo -e "${BOLD}${YELLOW}$action${RESET}"
    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Call the enable_monitor function
enable_monitor
