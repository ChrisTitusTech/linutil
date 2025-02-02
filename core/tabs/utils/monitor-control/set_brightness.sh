#!/bin/sh -e

. ../utility_functions.sh

# Function to adjust brightness for a selected monitor
adjust_monitor_brightness() {
    while true; do
        monitor_list=$(detect_connected_monitors)
        count=1

        clear
        printf "%b\n" "${YELLOW}=========================================${RC}"
        printf "%b\n" "${YELLOW}  Adjust Monitor Brightness${RC}"
        printf "%b\n" "${YELLOW}=========================================${RC}"
        printf "%b\n" "${YELLOW}Choose a monitor to adjust brightness:${RC}"
        echo "$monitor_list" | while IFS= read -r monitor; do
            echo "$count. $monitor"
            count=$((count + 1))
        done

        printf "%b" "Enter the number of the monitor (or 'q' to quit): "
        read -r monitor_choice

        if [ "$monitor_choice" = "q" ]; then
            printf "%b\n" "${RED}Exiting...${RC}"
            return
        fi

        if ! echo "$monitor_choice" | grep -qE '^[0-9]+$'; then
            printf "%b\n" "${RED}Invalid selection. Please try again.${RC}"
            printf "Press [Enter] to continue..."
            read -r _
            continue
        fi

        monitor_count=$(echo "$monitor_list" | wc -l)
        if [ "$monitor_choice" -lt 1 ] || [ "$monitor_choice" -gt "$monitor_count" ]; then
            printf "%b\n" "${RED}Invalid selection. Please try again.${RC}"
            printf "Press [Enter] to continue..."
            read -r _
            continue
        fi

        monitor_name=$(echo "$monitor_list" | sed -n "${monitor_choice}p")
        current_brightness=$(get_current_brightness "$monitor_name")

        current_brightness_percentage=$(awk -v brightness="$current_brightness" 'BEGIN {printf "%.0f", brightness * 100}')
        printf "%b\n" "${YELLOW}Current brightness for $monitor_name${RC}: ${GREEN}$current_brightness_percentage%${RC}"

        while true; do
            printf "%b" "Enter the new brightness value as a percentage (10 to 100, or 'q' to quit): "
            read -r new_brightness_percentage

            if [ "$new_brightness_percentage" = "q" ]; then
                printf "%b\n" "${RED}Exiting...${RC}"
                return
            fi

            # Validate brightness input: accept only values above 10
            if ! echo "$new_brightness_percentage" | grep -qE '^[0-9]+$' || [ "$new_brightness_percentage" -lt 10 ] || [ "$new_brightness_percentage" -gt 100 ]; then
                printf "%b\n" "${RED}Invalid brightness value. Please enter a value between 10 and 100.${RC}"
                continue
            fi

            # Convert percentage to xrandr brightness value (10% to 0.10)
            new_brightness=$(awk "BEGIN {printf \"%.2f\", $new_brightness_percentage / 100}")

            printf "%b" "Set brightness for $monitor_name to $new_brightness_percentage%? (y/N): "
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                printf "%b\n" "${GREEN}Setting brightness for $monitor_name to $new_brightness_percentage%${RC}"
                execute_command "xrandr --output $monitor_name --brightness $new_brightness"
                printf "%b\n" "${GREEN}Brightness for $monitor_name set to $new_brightness_percentage% successfully.${RC}"
                break
            else
                printf "%b\n" "${RED}Action canceled. Please choose a different brightness value.${RC}"
            fi
        done
    done
}

# Call the adjust_monitor_brightness function
adjust_monitor_brightness
