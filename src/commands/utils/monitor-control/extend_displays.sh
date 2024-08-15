#!/bin/bash
source ./utility_functions.sh

# Function to extend displays
extend_displays() {
    monitors=($(detect_connected_monitors))
    for ((i=1; i<${#monitors[@]}; i++)); do
        if confirm_action "Extend ${monitors[$i]} to the right of ${monitors[$((i-1))]}?"; then
            echo "Extending ${monitors[$i]} to the right of ${monitors[$((i-1))]}"
            execute_command "xrandr --output ${monitors[$i]} --right-of ${monitors[$((i-1))]}"
        fi
    done
}

extend_displays
