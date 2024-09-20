#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to Reset scaling back to 1 (native resolution) for all monitors
Reset_scaling() {
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Reset Monitor Scaling to Native Resolution${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"

    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    for monitor in $monitor_array; do
        printf "%b\n" "${CYAN}Resetting scaling for $monitor to 1x1 (native resolution)${RC}"
        execute_command "xrandr --output $monitor --scale 1x1"
    done

    printf "%b\n" "${GREEN}All monitor scalings have been Reset to 1x1.${RC}"
}

# Call the Reset_scaling function
Reset_scaling
