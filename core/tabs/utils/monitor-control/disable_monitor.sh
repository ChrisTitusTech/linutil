#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to disable a monitor
disable_monitor() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Disable Monitor${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "Choose a monitor to disable: "
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

    printf "%b\n" "${RED}Warning: Disabling the monitor will turn it off and may affect your display setup.${RC}"
    
    if confirm_action "Do you really want to disable ${GREEN}$monitor_name${RC}?"; then
        printf "%b\n" "${GREEN}Disabling $monitor_name${RC}"
        execute_command "xrandr --output $monitor_name --off"
        printf "%b\n" "${GREEN}Monitor $monitor_name disabled successfully.${RC}"
    else
        printf "%b\n" "${RED}Action canceled.${RC}"
    fi
}

# Function to prompt for confirmation
confirm_action() {
    action="$1"
    printf "%b\n" "${YELLOW}$action${RC}"
    printf "%b" "Are you sure? (y/N): "
    read -r confirm
    if echo "$confirm" | grep -qE '^[Yy]$'; then
        return 0
    else
        return 1
    fi
}

# Call the disable_monitor function
disable_monitor
