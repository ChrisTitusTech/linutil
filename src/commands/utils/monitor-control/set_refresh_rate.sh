#!/bin/sh -e

. ./utility_functions.sh

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'

# Function to set refresh rate
set_refresh_rate() {
    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -a monitor_array <<<"$monitor_list"
    
    while true; do
        clear
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${BLUE}  Monitor Refresh Rate Configuration${RESET}"
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${YELLOW}Choose a monitor to configure:${RESET}"
        for i in "${!monitor_array[@]}"; do
            echo -e "$((i + 1)). ${CYAN}${monitor_array[i]}${RESET}"
        done

        read -p "Enter the choice (or 'q' to quit): " monitor_choice

        if [[ "$monitor_choice" == "q" ]]; then
            echo -e "${RED}Exiting...${RESET}"
            return
        fi

        if ! [[ "$monitor_choice" =~ ^[0-9]+$ ]] || (( monitor_choice < 1 )) || (( monitor_choice > ${#monitor_array[@]} )); then
            echo -e "${RED}Invalid selection. Please try again.${RESET}"
            read -p "Press [Enter] to continue..."
            continue
        fi

        monitor_name="${monitor_array[monitor_choice - 1]}"
        
        # Get the current resolution
        current_resolution=$(xrandr | grep "^$monitor_name connected" | grep -oP "\d+x\d+")

        # Get available refresh rates for the current resolution
        refresh_rates=$(xrandr | grep -A1 "^$monitor_name connected" | grep "$current_resolution" | awk '{for (i=2; i<=NF; i++) print $i}' | sed 's/\*//')

        if [ -z "$refresh_rates" ]; then
            echo -e "${RED}No refresh rates found for $monitor_name with resolution $current_resolution.${RESET}"
            read -p "Press [Enter] to continue..."
            continue
        fi

        clear
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${BLUE}  Refresh Rate Configuration for ${CYAN}$monitor_name${RESET}"
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${YELLOW}Current resolution: $current_resolution${RESET}"
        echo -e "${YELLOW}Choose a refresh rate for $monitor_name:${RESET}"
        
        IFS=$'\n' read -r -a refresh_array <<<"$refresh_rates"
        for i in "${!refresh_array[@]}"; do
            echo -e "$((i + 1)). ${CYAN}${refresh_array[i]} Hz${RESET}"
        done

        read -p "Enter the choice (or 'q' to quit): " refresh_choice

        if [[ "$refresh_choice" == "q" ]]; then
            echo -e "${RED}Exiting...${RESET}"
            return
        fi

        if ! [[ "$refresh_choice" =~ ^[0-9]+$ ]] || (( refresh_choice < 1 )) || (( refresh_choice > ${#refresh_array[@]} )); then
            echo -e "${RED}Invalid selection. Please try again.${RESET}"
            continue
        fi

        # Map the index to the actual refresh rate
        selected_refresh_rate=${refresh_array[$refresh_choice - 1]}

        read -p "Set refresh rate for $monitor_name to $selected_refresh_rate Hz? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Setting refresh rate for $monitor_name to $selected_refresh_rate Hz${RESET}"
            execute_command "xrandr --output $monitor_name --mode $current_resolution --rate $selected_refresh_rate"
            break
        else
            echo -e "${RED}Action canceled. Please choose a different refresh rate.${RESET}"
        fi
    done
}

set_refresh_rate
