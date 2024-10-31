#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to extend displays
extend_displays() {
    monitors=$(detect_connected_monitors)
    monitor_array=$(echo "$monitors" | tr '\n' ' ')
    i=1
    for monitor in $monitor_array; do
        if [ "$i" -gt 1 ]; then
            prev_monitor=$(echo "$monitor_array" | cut -d' ' -f$((i-1)))
            if confirm_action "Extend $monitor to the right of $prev_monitor?"; then
                printf "%b\n" "${GREEN}Extending $monitor to the right of $prev_monitor${RC}"
                execute_command "xrandr --output $monitor --right-of $prev_monitor"
            fi
        fi
        i=$((i + 1))
    done
}

extend_displays
