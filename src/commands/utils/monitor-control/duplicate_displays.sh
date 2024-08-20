#!/bin/bash
source ./utility_functions.sh

# Function to duplicate displays
duplicate_displays() {
    primary=$(detect_connected_monitors | head -n 1)
    for monitor in $(detect_connected_monitors | tail -n +2); do
        if confirm_action "Duplicate $monitor to $primary?"; then
            echo "Duplicating $monitor to $primary"
            execute_command "xrandr --output $monitor --same-as $primary"
        fi
    done
}

duplicate_displays
