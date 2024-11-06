#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to set a monitor as primary
set_primary_monitor() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Set Primary Monitor${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}Choose a monitor to set as primary:${RC}"
    i=1
    for monitor in $monitor_array; do
        printf "%b\n" "$i. ${GREEN}$monitor${RC}"
        i=$((i + 1))
    done

    printf "%b" "Enter the number of the monitor to arrange: "
    read -r monitor_choice

    if ! echo "$monitor_choice" | grep -qE '^[0-9]+$' || [ "$monitor_choice" -lt 1 ] || [ "$monitor_choice" -gt "$((i - 1))" ]; then
        printf "%b\n" "${RED}Invalid selection.${RC}"
        return
    fi

    monitor_name=$(echo "$monitor_array" | cut -d' ' -f"$monitor_choice")

    if confirm_action "Set $monitor_name as the primary monitor?"; then
        printf "%b\n" "${GREEN}Setting $monitor_name as primary monitor${RC}"
        execute_command "xrandr --output $monitor_name --primary"
        printf "%b\n" "${GREEN}Monitor $monitor_name set as primary successfully.${RC}"
    else
        printf "%b\n" "${RED}Action canceled.${RC}"
    fi
}

# Call the set_primary_monitor function
set_primary_monitor
