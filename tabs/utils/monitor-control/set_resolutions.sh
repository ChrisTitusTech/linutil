#!/bin/sh -e

. ./utility_functions.sh

. ../../common-script.sh

# Function to set resolutions
set_resolutions() {
    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    while true; do
        clear
        printf "%b\n" "${YELLOW}=========================================${RC}"
        printf "%b\n" "${YELLOW}  Monitor Configuration${RC}"
        printf "%b\n" "${YELLOW}=========================================${RC}"

        printf "%b\n" "${YELLOW}Choose a monitor to configure:${RC}"
        i=1
        for monitor in $monitor_array; do
            printf "%b\n" "$i. ${YELLOW}$monitor${RC}"
            i=$((i + 1))
        done

        read -p "Enter the choice (or 'q' to quit): " monitor_choice

        if [ "$monitor_choice" = "q" ]; then
            printf "%b\n" "${RED}Exiting...${RC}"
            return
        fi

        if ! echo "$monitor_choice" | grep -qE '^[0-9]+$' || [ "$monitor_choice" -lt 1 ] || [ "$monitor_choice" -gt "$((i - 1))" ]; then
            printf "%b\n" "${RED}Invalid selection. Please try again.${RC}"
            read -p "Press [Enter] to continue..."
            continue
        fi

        monitor_name=$(echo "$monitor_array" | cut -d' ' -f"$monitor_choice")
        resolutions=$(get_unique_resolutions "$monitor_name" | sort -rn -t'x' -k1,1 -k2,2)

        temp_res_file=$(mktemp)
        echo "$resolutions" | awk '{print NR " " $0}' > "$temp_res_file"

        i=1
        while read -r resolution; do
            resolution_map[$i]="$resolution"
            i=$((i + 1))
        done < "$temp_res_file"

        clear
        printf "%b\n" "${YELLOW}=========================================${RC}"
        printf "%b\n" "${YELLOW}  Resolution Configuration for ${YELLOW}$monitor_name${RC}"
        printf "%b\n" "${YELLOW}=========================================${RC}"
        awk '{print $1 ". " $2}' "$temp_res_file"

        while true; do
            read -p "Enter the choice (or 'q' to quit): " resolution_choice

            if [ "$resolution_choice" = "q" ]; then
                printf "%b\n" "${RED}Exiting...${RC}"
                rm "$temp_res_file"
                return
            fi

            if ! echo "$resolution_choice" | grep -qE '^[0-9]+$' || [ "$resolution_choice" -lt 1 ] || [ "$resolution_choice" -gt "$((i - 1))" ]; then
                printf "%b\n" "${RED}Invalid selection. Please try again.${RC}"
                continue
            fi

            # Map the index to the actual resolution
            selected_resolution=${resolution_map[$resolution_choice]}

            read -p "Set resolution for $monitor_name to $selected_resolution? (y/n): " confirm
            if echo "$confirm" | grep -qE '^[Yy]$'; then
                printf "%b\n" "${GREEN}Setting resolution for $monitor_name to $selected_resolution${RC}"
                execute_command "xrandr --output $monitor_name --mode $selected_resolution"
                break
            else
                printf "%b\n" "${RED}Action canceled. Please choose a different resolution.${RC}"
            fi
        done

        rm "$temp_res_file"
    done
}

set_resolutions
