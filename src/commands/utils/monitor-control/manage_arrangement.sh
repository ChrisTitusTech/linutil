#!/bin/bash
source ./utils/monitor-control/utility_functions.sh

# Function to manage monitor arrangement
manage_arrangement() {
    monitor_list=$(detect_connected_monitors)
    IFS=$'\n' read -r -d '' -a monitor_array <<<"$monitor_list"

    clear
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${BLUE}  Manage Monitor Arrangement${RESET}"
    echo -e "${BLUE}=========================================${RESET}"
    echo -e "${YELLOW}Choose the monitor to arrange:${RESET}"
    for i in "${!monitor_array[@]}"; do
        echo -e "$((i + 1)). ${CYAN}${monitor_array[i]}${RESET}"
    done

    read -p "Enter the number of the monitor to arrange: " monitor_choice

    if ! [[ "$monitor_choice" =~ ^[0-9]+$ ]] || (( monitor_choice < 1 )) || (( monitor_choice > ${#monitor_array[@]} )); then
        echo -e "${RED}Invalid selection.${RESET}"
        return
    fi

    monitor_name="${monitor_array[monitor_choice - 1]}"

    clear
    echo -e "${YELLOW}Choose position relative to other monitors:${RESET}"
    echo -e "1. ${CYAN}Left of${RESET}"
    echo -e "2. ${CYAN}Right of${RESET}"
    echo -e "3. ${CYAN}Above${RESET}"
    echo -e "4. ${CYAN}Below${RESET}"

    read -p "Enter the number of the position: " position_choice

    case $position_choice in
        1) position="--left-of" ;;
        2) position="--right-of" ;;
        3) position="--above" ;;
        4) position="--below" ;;
        *) echo -e "${RED}Invalid selection.${RESET}"; return ;;
    esac

    echo -e "${YELLOW}Choose the reference monitor:${RESET}"
    for i in "${!monitor_array[@]}"; do
        if [[ "${monitor_array[i]}" != "$monitor_name" ]]; then
            echo -e "$((i + 1)). ${CYAN}${monitor_array[i]}${RESET}"
        fi
    done

    read -p "Enter the number of the reference monitor: " ref_choice

    if ! [[ "$ref_choice" =~ ^[0-9]+$ ]] || (( ref_choice < 1 )) || (( ref_choice > ${#monitor_array[@]} )) || (( ref_choice == monitor_choice )); then
        echo -e "${RED}Invalid selection.${RESET}"
        return
    fi

    ref_monitor="${monitor_array[ref_choice - 1]}"

    if confirm_action "Arrange ${CYAN}$monitor_name${RESET} ${position} ${CYAN}$ref_monitor${RESET}?"; then
        echo -e "${GREEN}Arranging $monitor_name ${position} $ref_monitor${RESET}"
        execute_command "xrandr --output $monitor_name $position $ref_monitor"
        echo -e "${GREEN}Arrangement updated successfully.${RESET}"
    else
        echo -e "${RED}Action canceled.${RESET}"
    fi
}

# Call the manage_arrangement function
manage_arrangement
