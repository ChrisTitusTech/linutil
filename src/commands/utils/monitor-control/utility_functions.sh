#!/bin/sh -e

. ../../common-script.sh

# Function to check bluetoothctl is installed
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

# Function to display colored text
colored_echo() {
    local color=$1
    local text=$2
    case $color in
    red) echo -e "\033[31m$text\033[0m" ;;
    green) echo -e "\033[32m$text\033[0m" ;;
    yellow) echo -e "\033[33m$text\033[0m" ;;
    blue) echo -e "\033[34m$text\033[0m" ;;
    *) echo "$text" ;;
    esac
}

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
    # Get available resolutions from xrandr without line limit
    available_resolutions=$(echo "$xrandr_output" | sed -n "/$monitor connected/,/^[^ ]/p" | grep -oP '\d+x\d+' | sort -u)
    
    # Define standard resolutions
    standard_resolutions="1920x1080 1280x720 1600x900 2560x1440 3840x2160"
    
    # Filter standard resolutions to include only those available for the monitor
    filtered_standard_resolutions=$(echo "$standard_resolutions" | tr ' ' '\n' | grep -xF -f <(echo "$available_resolutions"))
    
    # Get remaining available resolutions (excluding standard ones)
    remaining_resolutions=$(comm -23 <(echo "$available_resolutions" | sort) <(echo "$filtered_standard_resolutions" | sort))
    
    # Combine filtered standard resolutions and remaining resolutions, and limit to 10 results
    echo -e "$filtered_standard_resolutions\n$remaining_resolutions" | head -n 10
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

checkEnv
setup_xrandr