#!/bin/sh -e

. ../../common-script.sh

# Function to check xrandr is installed
setup_xrandr() {
    printf "%b\n" "${YELLOW}Installing xrandr...${RC}"
    if ! command_exists xrandr; then
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm xorg-xrandr
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y x11-xserver-utils
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add xrandr
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y xorg-x11-server-utils
                ;;
        esac
    else
        printf "%b\n" "${GREEN}xrandr is already installed.${RC}"
    fi
}

# Function to execute xrandr commands and handle errors
execute_command() {
    command="$1"
    printf "Executing: %s\n" "$command"
    eval "$command" 2>&1 | tee /tmp/xrandr.log | tail -n 20
    if [ $? -ne 0 ]; then
        printf "%b\n" "${RED}An error occurred while executing the command. Check /tmp/xrandr.log for details.${RC}"
    fi
}

# Function to detect connected monitors
detect_connected_monitors() {
    xrandr_output=$(xrandr)
    printf "%b\n" "$xrandr_output" | grep " connected" | awk '{print $1}'
}

# Function to get the current brightness for a monitor
get_current_brightness() {
    monitor="$1"
    xrandr --verbose | grep -A 10 "^$monitor connected" | grep "Brightness:" | awk '{print $2}'
}

# Function to get resolutions for a monitor
get_unique_resolutions() {
    monitor="$1"
    xrandr_output=$(xrandr)
    available_resolutions=$(printf "%s" "$xrandr_output" | sed -n "/$monitor connected/,/^[^ ]/p" | grep -oP '\d+x\d+' | sort -u)
    
    standard_resolutions="1920x1080 1280x720 1600x900 2560x1440 3840x2160"
    
    temp_file=$(mktemp)
    printf "%s" "$available_resolutions" > "$temp_file"
    
    filtered_standard_resolutions=$(printf "%s" "$standard_resolutions" | tr ' ' '\n' | grep -xF -f "$temp_file")
    
    rm "$temp_file"
    
    available_res_file=$(mktemp)
    filtered_standard_res_file=$(mktemp)
    printf "%s" "$available_resolutions" | sort > "$available_res_file"
    printf "%s" "$filtered_standard_resolutions" | sort > "$filtered_standard_res_file"
    
    remaining_resolutions=$(comm -23 "$available_res_file" "$filtered_standard_res_file")
    
    rm "$available_res_file" "$filtered_standard_res_file"
    
    printf "%b\n" "$filtered_standard_resolutions\n$remaining_resolutions" | head -n 10
}

# Function to prompt for confirmation
confirm_action() {
    action="$1"
    printf "%b\n" "${CYAN}$action${RC}"
    printf "%b" "${CYAN}Are you sure? (y/N): ${RC}"
    read -r confirm
    if echo "$confirm" | grep -qE '^[Yy]$'; then
        return 0
    else
        return 1
    fi
}

checkEmpty() {
    if [ -z "$1" ]; then
        printf "%b\n" "${RED}Empty value is not allowed${RC}" >&2
        exit 1
    fi
}

checkGroups() {
    groups="$1"
    available_groups="$2"
    for group in $groups; do
        if ! echo "$available_groups" | grep -q -w "$group"; then
            return 1
        fi
    done
    return 0
}

confirmAction() {
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        printf "%b\n" "${RED}Cancelled operation...${RC}" >&2
        exit 1
    fi
}

checkEnv
checkEscalationTool
setup_xrandr
