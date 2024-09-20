#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to duplicate displays
duplicate_displays() {
    primary=$(detect_connected_monitors | head -n 1)
    for monitor in $(detect_connected_monitors | tail -n +2); do
        if confirm_action "Duplicate $monitor to $primary?"; then
            printf "%b\n" "${GREEN}Duplicating $monitor to $primary${RC}"
            execute_command "xrandr --output $monitor --same-as $primary"
        fi
    done
}

duplicate_displays
