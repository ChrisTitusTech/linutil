#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to change monitor orientation
change_orientation() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Change Monitor Orientation${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}Choose a monitor to configure: ${RC}"
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

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Set Orientation for $monitor_name${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}Choose orientation:${RC}"
    printf "%b\n" "1. ${GREEN}Normal${RC}"
    printf "%b\n" "2. ${GREEN}Left${RC}"
    printf "%b\n" "3. ${GREEN}Right${RC}"
    printf "%b\n" "4. ${GREEN}Inverted${RC}"

    printf "%b" "Enter the number of the orientation: "
    read -r orientation_choice
    case $orientation_choice in
        1) orientation="normal" ;;
        2) orientation="left" ;;
        3) orientation="right" ;;
        4) orientation="inverted" ;;
        *) printf "%b\n" "${RED}Invalid selection.${RC}"; return ;;
    esac

    if confirm_action "Change orientation of $monitor_name to $orientation?"; then
        printf "%b\n" "${GREEN}Changing orientation of $monitor_name to $orientation${RC}"
        execute_command "xrandr --output $monitor_name --rotate $orientation"
        printf "%b\n" "${GREEN}Orientation changed successfully.${RC}"
    else
        printf "%b\n" "${RED}Action canceled.${RC}"
    fi
}

# Call the change_orientation function
change_orientation
