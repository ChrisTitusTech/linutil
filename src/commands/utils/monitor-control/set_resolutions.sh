#!/bin/bash
source ./utils/monitor-control/utility_functions.sh

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'

# Function to set resolutions
set_resolutions() {
    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -d '' -a monitor_array <<<"$monitor_list"
    
    while true; do
        clear
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${BLUE}  Monitor Configuration${RESET}"
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
        resolutions=$(get_unique_resolutions "$monitor_name")

        # Create a temporary file with sorted resolutions and indices
        temp_res_file=$(mktemp)
        echo "$resolutions" | sort -nr | awk '{print NR " " $0}' > "$temp_res_file"

        # Read the sorted resolutions into an associative array
        declare -A resolution_map
        while read -r index resolution; do
            resolution_map[$index]="$resolution"
        done < "$temp_res_file"

        clear
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${BLUE}  Resolution Configuration for ${CYAN}$monitor_name${RESET}"
        echo -e "${BLUE}=========================================${RESET}"
        echo -e "${YELLOW}Choose resolution for $monitor_name:${RESET}"
        awk '{print $1 ". " $2}' "$temp_res_file"

        while true; do
            read -p "Enter the choice (or 'q' to quit): " resolution_choice

            if [[ "$resolution_choice" == "q" ]]; then
                echo -e "${RED}Exiting...${RESET}"
                rm "$temp_res_file"
                return
            fi

            if ! [[ "$resolution_choice" =~ ^[0-9]+$ ]] || (( resolution_choice < 1 )) || (( resolution_choice > ${#resolution_map[@]} )); then
                echo -e "${RED}Invalid selection. Please try again.${RESET}"
                continue
            fi

            # Map the index to the actual resolution
            selected_resolution=${resolution_map[$resolution_choice]}

            read -p "Set resolution for $monitor_name to $selected_resolution? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}Setting resolution for $monitor_name to $selected_resolution${RESET}"
                execute_command "xrandr --output $monitor_name --mode $selected_resolution"
                break
            else
                echo -e "${RED}Action canceled. Please choose a different resolution.${RESET}"
            fi
        done

        # Clean up the temporary file
        rm "$temp_res_file"
    done
}

set_resolutions
