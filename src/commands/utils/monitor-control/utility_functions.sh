#!/bin/bash

# Function to execute xrandr commands and handle errors
execute_command() {
    local command="$1"
    echo "Executing: $command"
    eval "$command" 2>&1 | tee /tmp/xrandr.log | tail -n 20
    if [ $? -ne 0 ]; then
        echo "An error occurred while executing the command. Check /tmp/xrandr.log for details."
    fi
}

# Function to detect connected monitors
detect_connected_monitors() {
    xrandr_output=$(xrandr)
    echo "$xrandr_output" | grep " connected" | awk '{print $1}'
}

# Function to get resolutions for a monitor
get_unique_resolutions() {
    local monitor="$1"
    xrandr_output=$(xrandr)
    echo "$xrandr_output" | grep -A 10 "$monitor connected" | grep -oP '\d+x\d+' | sort -u
}

# Function to prompt for confirmation
confirm_action() {
    local action="$1"
    echo "$action"
    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}
