#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to manage monitor arrangement
manage_arrangement() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    clear
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Manage Monitor Arrangement${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}Choose the monitor to arrange: ${RC}"
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

    clear
    printf "%b" "${YELLOW}Choose position relative to other monitors: ${RC}"
    printf "%b\n" "1. ${YELLOW}Left of${RC}"
    printf "%b\n" "2. ${YELLOW}Right of${RC}"
    printf "%b\n" "3. ${YELLOW}Above${RC}"
    printf "%b\n" "4. ${YELLOW}Below${RC}"

    printf "%b" "Enter the number of the position: "
    read -r position_choice

    case $position_choice in
        1) position="--left-of" ;;
        2) position="--right-of" ;;
        3) position="--above" ;;
        4) position="--below" ;;
        *) printf "%b\n" "${RED}Invalid selection.${RC}"; return ;;
    esac

    printf "%b\n" "${YELLOW}Choose the reference monitor:${RC}"
    for i in $monitor_array; do
        if [ "$i" != "$monitor_name" ]; then
            printf "%b\n" "$((i + 1)). ${YELLOW}$i${RC}"
        fi
    done

    printf "%b" "Enter the number of the reference monitor: "
    read -r ref_choice

    if ! echo "$ref_choice" | grep -qE '^[0-9]+$' || [ "$ref_choice" -lt 1 ] || [ "$ref_choice" -gt "$((i - 1))" ] || [ "$ref_choice" -eq "$monitor_choice" ]; then
        printf "%b\n" "${RED}Invalid selection.${RC}"
        return
    fi

    ref_monitor=$(echo "$monitor_array" | cut -d' ' -f"$ref_choice")

    if confirm_action "Arrange ${YELLOW}$monitor_name${RC} ${position} ${YELLOW}$ref_monitor${RC}?"; then
        printf "%b\n" "${GREEN}Arranging $monitor_name ${position} $ref_monitor${RC}"
        execute_command "xrandr --output $monitor_name $position $ref_monitor"
        printf "%b\n" "${GREEN}Arrangement updated successfully.${RC}"
    else
        printf "%b\n" "${RED}Action canceled.${RC}"
    fi
}

# Call the manage_arrangement function
manage_arrangement
