#!/bin/sh -e

. ../../common-script.sh

# Function to check xrandr is installed
setup_xrandr() {
    echo "Install xrandr if not already installed..."
    if ! command_exists xrandr; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --noconfirm xorg-xrandr
                ;;
            apt-get)
                $ESCALATION_TOOL "${PACKAGER}" install -y x11-xserver-utils
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y xorg-x11-server-utils
                ;;
        esac
    else
        echo "xrandr is already installed."
    fi
}

# Function to execute xrandr commands and handle errors
execute_command() {
    command="$1"
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
    monitor="$1"
    xrandr_output=$(xrandr)
    # Get available resolutions from xrandr without line limit
    available_resolutions=$(echo "$xrandr_output" | sed -n "/$monitor connected/,/^[^ ]/p" | grep -oP '\d+x\d+' | sort -u)
    
    # Define standard resolutions
    standard_resolutions="1920x1080 1280x720 1600x900 2560x1440 3840x2160"
    
    temp_file=$(mktemp)
    echo "$available_resolutions" > "$temp_file"
    
    # Filter standard resolutions to include only those available for the monitor
    filtered_standard_resolutions=$(echo "$standard_resolutions" | tr ' ' '\n' | grep -xF -f "$temp_file")
    
    rm "$temp_file"
    
    available_res_file=$(mktemp)
    filtered_standard_res_file=$(mktemp)
    echo "$available_resolutions" | sort > "$available_res_file"
    echo "$filtered_standard_resolutions" | sort > "$filtered_standard_res_file"
    
    # Get remaining available resolutions (excluding standard ones)
    remaining_resolutions=$(comm -23 "$available_res_file" "$filtered_standard_res_file")
    
    rm "$available_res_file" "$filtered_standard_res_file"
    
    # Combine filtered standard resolutions and remaining resolutions, and limit to 10 results
    printf "%b\n" "$filtered_standard_resolutions\n$remaining_resolutions" | head -n 10
}

# Function to prompt for confirmation
confirm_action() {
    action="$1"
    echo "$action"
    read -p "Are you sure? (y/n): " confirm
    if echo "$confirm" | grep -qE '^[Yy]$'; then
        return 0
    else
        return 1
    fi
}

checkEnv
setup_xrandr