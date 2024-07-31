#!/bin/bash

# Function to execute xrandr commands and handle errors
execute_command() {
    local command="$1"
    echo "Executing: $command"
    eval "$command" 2>&1 | tee /tmp/xrandr.log | tail -n 20
    if [ $? -ne 0 ]; then
        dialog --msgbox "An error occurred while executing the command. Check /tmp/xrandr.log for details." 10 60
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
    dialog --title "Confirmation" --yesno "$action" 10 60
    return $?
}

# Function to set resolutions
set_resolutions() {
    monitor_list=$(detect_connected_monitors)
    selected_monitor=$(dialog --title "Select Monitor" --menu "Choose a monitor to configure:" 15 60 10 $(echo "$monitor_list" | awk '{print NR " " $0}') 3>&1 1>&2 2>&3)

    if [ -z "$selected_monitor" ]; then
        return
    fi

    monitor_name=$(echo "$monitor_list" | sed -n "${selected_monitor}p")
    resolutions=$(get_unique_resolutions "$monitor_name")

    # Create a temporary file to store resolutions with indices
    temp_res_file=$(mktemp)
    echo "$resolutions" | awk '{print NR " " $0}' > "$temp_res_file"

    selected_resolution_index=$(dialog --title "Select Resolution" --menu "Choose resolution for $monitor_name:" 15 60 10 $(cat "$temp_res_file") 3>&1 1>&2 2>&3)
    
    # Clean up the temporary file
    rm "$temp_res_file"

    if [ -z "$selected_resolution_index" ]; then
        return
    fi

    # Map the index to the actual resolution
    selected_resolution=$(echo "$resolutions" | sed -n "${selected_resolution_index}p")

    if confirm_action "Set resolution for $monitor_name to $selected_resolution?"; then
        echo "Setting resolution for $monitor_name to $selected_resolution"
        execute_command "xrandr --output $monitor_name --mode $selected_resolution"
    fi
}

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

# Function to auto-detect displays and set common resolution
auto_detect_displays() {
    if confirm_action "Auto-detect displays and set common resolution?"; then
        execute_command "xrandr --auto"
        
        monitors=$(detect_connected_monitors)
        first_monitor=$(echo "$monitors" | head -n 1)
        common_resolutions=$(get_unique_resolutions "$first_monitor")

        for monitor in $monitors; do
            resolutions=$(get_unique_resolutions "$monitor")
            common_resolutions=$(comm -12 <(echo "$common_resolutions") <(echo "$resolutions"))
        done
        
        if [ -z "$common_resolutions" ]; then
            dialog --msgbox "No common resolution found among connected monitors." 10 60
            return
        fi

        highest_resolution=$(echo "$common_resolutions" | sort -n -t'x' -k1,1 -k2,2 | tail -n 1)

        for monitor in $monitors; do
            echo "Setting resolution for $monitor to $highest_resolution"
            execute_command "xrandr --output $monitor --mode $highest_resolution"
        done
    fi
}

# Function to enable a monitor
enable_monitor() {
    monitor_list=$(detect_connected_monitors)
    selected_monitor=$(dialog --title "Select Monitor" --menu "Choose a monitor to enable:" 15 60 10 $(echo "$monitor_list" | awk '{print NR " " $0}') 3>&1 1>&2 2>&3)

    if [ -z "$selected_monitor" ]; then
        return
    fi

    monitor_name=$(echo "$monitor_list" | sed -n "${selected_monitor}p")# Function to set resolutions
}

# Function to set resolutions
set_resolutions() {
    monitor_list=$(detect_connected_monitors)
    selected_monitor=$(dialog --title "Select Monitor" --menu "Choose a monitor to configure:" 15 60 10 $(echo "$monitor_list" | awk '{print NR " " $0}') 3>&1 1>&2 2>&3)

    if [ -z "$selected_monitor" ]; then
        return
    fi

    monitor_name=$(echo "$monitor_list" | sed -n "${selected_monitor}p")
    resolutions=$(get_unique_resolutions "$monitor_name")

    # Create a temporary file with sorted resolutions and indices
    temp_res_file=$(mktemp)
    echo "$resolutions" | sort -nr | awk '{print NR " " $0}' > "$temp_res_file"

    # Read the sorted resolutions into an associative array
    declare -A resolution_map
    while read -r index resolution; do
        resolution_map[$index]="$resolution"
    done < "$temp_res_file"

    # Create a list for the dialog menu
    dialog_list=$(awk '{print $1 " " $2}' "$temp_res_file")

    selected_resolution_index=$(dialog --title "Select Resolution" --menu "Choose resolution for $monitor_name:" 15 60 10 $dialog_list 3>&1 1>&2 2>&3)
    
    # Clean up the temporary file
    rm "$temp_res_file"

    if [ -z "$selected_resolution_index" ]; then
        return
    fi

    # Map the index to the actual resolution
    selected_resolution=${resolution_map[$selected_resolution_index]}

    if confirm_action "Set resolution for $monitor_name to $selected_resolution?"; then
        echo "Setting resolution for $monitor_name to $selected_resolution"
        execute_command "xrandr --output $monitor_name --mode $selected_resolution"
    fi
}



# Function to disable a monitor
disable_monitor() {
    monitor_list=$(detect_connected_monitors)
    selected_monitor=$(dialog --title "Select Monitor" --menu "Choose a monitor to disable:" 15 60 10 $(echo "$monitor_list" | awk '{print NR " " $0}') 3>&1 1>&2 2>&3)

    if [ -z "$selected_monitor" ]; then
        return
    fi

    monitor_name=$(echo "$monitor_list" | sed -n "${selected_monitor}p")

    if confirm_action "Disable $monitor_name?"; then
        echo "Disabling $monitor_name"
        execute_command "xrandr --output $monitor_name --off"
    fi
}

# Main menu
while true; do
    choice=$(dialog --title "Monitor Manager" --menu "Choose an action:" 15 60 8 \
        1 "Set Resolutions" \
        2 "Duplicate Displays" \
        3 "Extend Displays" \
        4 "Auto Detect Displays" \
        5 "Enable Monitor" \
        6 "Disable Monitor" \
        7 "Quit" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1) set_resolutions ;;
        2) duplicate_displays ;;
        3) extend_displays ;;
        4) auto_detect_displays ;;
        5) enable_monitor ;;
        6) disable_monitor ;;
        7) break ;;
        *) dialog --msgbox "Invalid choice, please try again." 10 40 ;;
    esac
done

clear