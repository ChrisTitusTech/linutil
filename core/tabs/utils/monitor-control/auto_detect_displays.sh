#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to auto-detect displays and set common resolution
auto_detect_displays() {
    if confirm_action "Auto-detect displays and set common resolution?"; then
        execute_command "xrandr --auto"
        
        monitors=$(detect_connected_monitors)
        first_monitor=$(echo "$monitors" | head -n 1)
        common_resolutions=$(get_unique_resolutions "$first_monitor")

        for monitor in $monitors; do
            resolutions=$(get_unique_resolutions "$monitor")
            temp_common_resolutions=$(mktemp)
            temp_resolutions=$(mktemp)

            printf "%b\n" "$common_resolutions" > "$temp_common_resolutions"
            printf "%b\n" "$resolutions" > "$temp_resolutions"

            common_resolutions=$(comm -12 "$temp_common_resolutions" "$temp_resolutions")

            rm -f "$temp_common_resolutions" "$temp_resolutions"
        done
        
        if [ -z "$common_resolutions" ]; then
            printf "%b\n" "${RED}No common resolution found among connected monitors.${RC}"
            return
        fi

        highest_resolution=$(echo "$common_resolutions" | sort -n -t'x' -k1,1 -k2,2 | tail -n 1)

        for monitor in $monitors; do
            printf "%b\n" "${YELLOW}Setting resolution for $monitor to $highest_resolution...${RC}"
            execute_command "xrandr --output $monitor --mode $highest_resolution"
        done
    fi
}

auto_detect_displays
