#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to enable a monitor
enable_monitor() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Enable Monitor${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}Choose a monitor to enable: ${RC}"
    
    i=1
    for monitor in $monitor_array; do
        printf "%b\n" "$i. ${GREEN}$monitor${RC}"
        i=$((i + 1))
    done

    printf "%b" "Enter the number of the monitor: "
    read -r monitor_choice

    if ! echo "$monitor_choice" | grep -qE '^[0-9]+$' || [ "$monitor_choice" -lt 1 ] || [ "$monitor_choice" -gt "$((i - 1))" ]; then
        printf "%b\n" "${RED}Invalid selection.${RC}"
        return
    fi

    monitor_name=$(echo "$monitor_array" | cut -d' ' -f"$monitor_choice")

    if confirm_action "Enable $monitor_name?"; then
        printf "%b\n" "${GREEN}Enabling $monitor_name${RC}"
        execute_command "xrandr --output $monitor_name --auto"
        printf "%b\n" "${GREEN}Monitor $monitor_name enabled successfully.${RC}"
    else
        printf "%b\n" "${RED}Action canceled.${RC}"
    fi
}

# Call the enable_monitor function
enable_monitor
