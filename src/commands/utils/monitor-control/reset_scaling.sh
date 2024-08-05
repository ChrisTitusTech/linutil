#!/bin/bash
source ./utils/monitor-control/utility_functions.sh

# Function to reset scaling back to 1 (native resolution) for all monitors
reset_scaling() {
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${BLUE}  Reset Monitor Scaling to Native Resolution${RESET}"
    echo -e "${BLUE}=========================================${RESET}"

    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -d '' -a monitor_array <<<"$monitor_list"

    for monitor in "${monitor_array[@]}"; do
        echo -e "${CYAN}Resetting scaling for $monitor to 1x1 (native resolution)${RESET}"
        execute_command "xrandr --output $monitor --scale 1x1"
    done

    echo -e "${GREEN}All monitor scalings have been reset to 1x1.${RESET}"
}

# Call the reset_scaling function
reset_scaling
