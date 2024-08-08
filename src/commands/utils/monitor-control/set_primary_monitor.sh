#!/bin/bash
source ./utils/monitor-control/utility_functions.sh

# Function to set a monitor as primary
set_primary_monitor() {
    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -d '' -a monitor_array <<<"$monitor_list"

    clear
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${BLUE}  Set Primary Monitor${RESET}"
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${YELLOW}Choose a monitor to set as primary:${RESET}"
    for i in "${!monitor_array[@]}"; do
        echo -e "$((i + 1)). ${CYAN}${monitor_array[i]}${RESET}"
    done

    read -p "Enter the number of the monitor: " monitor_choice

    if ! [[ "$monitor_choice" =~ ^[0-9]+$ ]] || (( monitor_choice < 1 )) || (( monitor_choice > ${#monitor_array[@]} )); then
        echo -e "${RED}Invalid selection.${RESET}"
        return
    fi

    monitor_name="${monitor_array[monitor_choice - 1]}"

    if confirm_action "Set ${CYAN}$monitor_name${RESET} as the primary monitor?"; then
        echo -e "${GREEN}Setting $monitor_name as primary monitor${RESET}"
        execute_command "xrandr --output $monitor_name --primary"
        echo -e "${GREEN}Monitor $monitor_name set as primary successfully.${RESET}"
    else
        echo -e "${RED}Action canceled.${RESET}"
    fi
}

# Call the set_primary_monitor function
set_primary_monitor
