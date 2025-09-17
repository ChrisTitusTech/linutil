#!/bin/sh -e

. ../../common-script.sh

# Check for required commands and install any that are missing
required_commands="find git stty rsync"
missing_commands=""

# First pass: identify missing commands
for cmd in $required_commands; do
    if ! command_exists "$cmd"; then
        missing_commands="$missing_commands $cmd"
    fi
done

# Second pass: install missing commands
if [ -n "$missing_commands" ]; then
    printf "%b\n" "${YELLOW}Missing commands detected:$missing_commands${RC}"
    printf "%b\n" "${YELLOW}Attempting to install missing commands...${RC}"
    
    for cmd in $missing_commands; do
        printf "%b\n" "${YELLOW}Installing $cmd...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$cmd"
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add "$cmd"
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy "$cmd"
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$cmd"
                ;;
        esac
        
        # Verify installation was successful
        if command_exists "$cmd"; then
            printf "%b\n" "${GREEN}Successfully installed $cmd${RC}"
        else
            printf "%b\n" "${RED}Failed to install $cmd${RC}"
            exit 1
        fi
    done
    
    printf "%b\n" "${GREEN}All required commands are now installed.${RC}"
else
    printf "%b\n" "${GREEN}All required commands are already installed.${RC}"
fi

# Global variable to store found steamapps directories
steamapps_dirs=""

# Function to find and cache all steamapps directories
find_steamapps_dirs() {
    if [ -n "$steamapps_dirs" ]; then
        return 0
    fi
    
    printf "%b\n" "${YELLOW}Searching for Steam library folders...${RC}" >&2
    printf "%b\n" "${YELLOW}This may take a moment...${RC}" >&2
    
    # Show progress by searching locations sequentially
    temp_file="/tmp/steamapps_search_$$"
    
    printf "%b" "${YELLOW}Searching home directory...${RC}" >&2
    find "$HOME" -type d -name "steamapps" 2>/dev/null > "$temp_file" || true
    printf "%b\n" " ${GREEN}✓${RC}" >&2
    home_steamapps=$(head -20 "$temp_file" 2>/dev/null)
    
    # Search in /media for external drives
    media_steamapps=""
    if [ -d "/media" ]; then
        printf "%b" "${YELLOW}Searching /media...${RC}" >&2
        find "/media" -type d -name "steamapps" 2>/dev/null > "$temp_file" || true
        media_steamapps=$(head -10 "$temp_file" 2>/dev/null)
        printf "%b\n" " ${GREEN}✓${RC}" >&2
    fi
    
    # Search in /mnt for additional mount points
    mnt_steamapps=""
    if [ -d "/mnt" ]; then
        printf "%b" "${YELLOW}Searching /mnt...${RC}" >&2
        find "/mnt" -type d -name "steamapps" 2>/dev/null > "$temp_file" || true
        mnt_steamapps=$(head -10 "$temp_file" 2>/dev/null)
        printf "%b\n" " ${GREEN}✓${RC}" >&2
    fi
    
    # Clean up temporary file
    rm -f "$temp_file" 2>/dev/null || true
    
    # Combine results and filter out any potential garbage
    steamapps_dirs=""
    for result in "$home_steamapps" "$media_steamapps" "$mnt_steamapps"; do
        if [ -n "$result" ]; then
            # Filter to only include valid directory paths that actually exist
            filtered_result=""
            IFS='
'
            for path in $result; do
                # Ensure it's a valid path and actually exists
                if [ -d "$path" ] && echo "$path" | grep -q "steamapps$"; then
                    if [ -z "$filtered_result" ]; then
                        filtered_result="$path"
                    else
                        filtered_result="$filtered_result
$path"
                    fi
                fi
            done
            IFS=' '
            
            if [ -n "$filtered_result" ]; then
                if [ -z "$steamapps_dirs" ]; then
                    steamapps_dirs="$filtered_result"
                else
                    steamapps_dirs="$steamapps_dirs
$filtered_result"
                fi
            fi
        fi
    done
    
    if [ -z "$steamapps_dirs" ]; then
        printf "%b\n" "${RED}No Steam library folders found.${RC}"
        return 1
    fi
    
    printf "%b\n" "${GREEN}Found Steam library folders.${RC}"
    return 0
}

# Function to search for compatdata paths in known steamapps directories
find_compatdata_paths() {
    printf "%b\n" "${YELLOW}Searching for Fallout 76 compatdata paths...${RC}" >&2
    
    if ! find_steamapps_dirs; then
        return 1
    fi
    
    compatdata_paths=""
    IFS='
'
    for steam_dir in $steamapps_dirs; do
        compatdata_path="$steam_dir/compatdata/1151340/pfx/drive_c/users/steamuser/Documents/My Games/Fallout 76"
        if [ -d "$compatdata_path" ]; then
            compatdata_paths="$compatdata_paths$compatdata_path
"
        fi
    done
    IFS=' '
    
    if [ -z "$compatdata_paths" ]; then
        printf "%b\n" "${RED}No compatdata folders found.${RC}"
        return 1
    fi
    
    echo "$compatdata_paths"
}

# Function to search for common game paths in known steamapps directories
find_common_paths() {
    printf "%b\n" "${YELLOW}Searching for Fallout 76 common game paths...${RC}" >&2

    if ! find_steamapps_dirs; then
        return 1
    fi
    
    common_paths=""
    IFS='
'
    for steam_dir in $steamapps_dirs; do
        fo76_path="$steam_dir/common/Fallout76"
        if [ -d "$fo76_path" ]; then
            common_paths="$common_paths$fo76_path
"
        fi
    done
    IFS=' '
    
    if [ -z "$common_paths" ]; then
        printf "%b\n" "${RED}No common game folders found.${RC}" >&2
        return 1
    fi
    
    echo "$common_paths"
}

# Function to display numbered menu for path selection
print_numbered_menu() {
    clear
    printf "%b\n" "${CYAN}$menu_title${RC}"
    printf "%b\n" "${YELLOW}Select an option by entering the number:${RC}"
    printf "\n"
    
    i=1
    IFS='|'
    for path in $paths_string; do
        if [ -n "$path" ] && [ -d "$path" ]; then
            printf "%b%d)%b %s\n" "${GREEN}" "$i" "${RC}" "$path"
            i=$((i + 1))
        fi
    done
    IFS=' '
    
    printf "\n%bEnter your choice (1-%d), or 'q' to quit: %b" "${YELLOW}" "$total" "${RC}"
}

# Function to handle path selection with numbered menu (pseudo-terminal compatible)
select_path_numbered() {
    while true; do
        print_numbered_menu
        read -r choice
        
        case "$choice" in
            q|Q)
                printf "%b\n" "${RED}Selection cancelled by user.${RC}"
                exit 1
                ;;
            ''|*[!0-9]*)
                printf "%b\n" "${RED}Invalid input. Please enter a number between 1 and $total.${RC}"
                sleep 2
                ;;
            *)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
                    # Extract the path more safely
                    selected_path=""
                    current_index=1
                    IFS='|'
                    for path in $paths_string; do
                        if [ -n "$path" ] && [ -d "$path" ]; then
                            if [ $current_index -eq "$choice" ]; then
                                selected_path="$path"
                                break
                            fi
                            current_index=$((current_index + 1))
                        fi
                    done
                    IFS=' '
                    
                    if [ -n "$selected_path" ]; then
                        break
                    else
                        printf "%b\n" "${RED}Invalid selection. Please try again.${RC}"
                        sleep 2
                    fi
                else
                    printf "%b\n" "${RED}Invalid choice. Please enter a number between 1 and $total.${RC}"
                    sleep 2
                fi
                ;;
        esac
    done
    
    clear
    printf "%b\n" "${GREEN}Selected: $selected_path${RC}"
}

# Function to check if we're in a full terminal or pseudo-terminal
check_terminal_capabilities() {
    # Check if we have a proper terminal with arrow key support
    if [ -t 0 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
        # Try to detect if terminal supports advanced features
        if command_exists tput && tput colors >/dev/null 2>&1; then
            return 0  # Full terminal capabilities
        fi
    fi
    return 1  # Limited terminal or pseudo-terminal
}

# Function to display interactive menu (for full terminals)
print_interactive_menu() {
    clear
    printf "%b\n" "${CYAN}$menu_title${RC}"
    printf "%b\n" "${YELLOW}Use arrow keys (↑/↓) or j/k to navigate, Enter to select, 'q' to quit${RC}"
    printf "\n"
    
    i=0
    IFS='|'
    for path in $paths_string; do
        if [ -n "$path" ] && [ -d "$path" ]; then
            if [ $i -eq $selected ]; then
                printf "%b> %s%b\n" "${GREEN}" "$path" "${RC}"
            else
                printf "  %s\n" "$path"
            fi
            i=$((i + 1))
        fi
    done
    IFS=' '
    
    printf "\n"
}

# Function to read a single character including escape sequences
read_key() {
    stty -icanon -echo min 1 time 0 2>/dev/null || return 1
    key=""
    char=$(dd bs=1 count=1 2>/dev/null)
    
    if [ "$char" = "$(printf '\033')" ]; then
        # Escape sequence detected, read the next two characters
        char2=$(dd bs=1 count=1 2>/dev/null)
        char3=$(dd bs=1 count=1 2>/dev/null)
        key="ESC[$char2$char3"
    else
        key="$char"
    fi
    
    stty icanon echo 2>/dev/null || true
    echo "$key"
}

# Function to handle interactive path selection (for full terminals)
select_path_interactive() {
    selected=0
    print_interactive_menu
    
    while true; do
        if ! key=$(read_key); then
            # Fall back to numbered menu if key reading fails
            select_path_numbered
            return
        fi
        
        case "$key" in
            "ESC[[A" | "k")  # Up arrow or k
                if [ $selected -gt 0 ]; then
                    selected=$((selected - 1))
                    print_interactive_menu
                fi
                ;;
            "ESC[[B" | "j")  # Down arrow or j
                if [ $selected -lt $((total - 1)) ]; then
                    selected=$((selected + 1))
                    print_interactive_menu
                fi
                ;;
            "$(printf '\n')" | "$(printf '\r')")  # Enter
                # Extract the selected path safely
                current_index=0
                IFS='|'
                for path in $paths_string; do
                    if [ -n "$path" ] && [ -d "$path" ]; then
                        if [ $current_index -eq $selected ]; then
                            selected_path="$path"
                            break
                        fi
                        current_index=$((current_index + 1))
                    fi
                done
                IFS=' '
                
                if [ -n "$selected_path" ]; then
                    break
                fi
                ;;
            "q" | "Q")  # Quit option
                printf "%b\n" "${RED}Selection cancelled by user.${RC}"
                exit 1
                ;;
        esac
    done
    
    clear
    printf "%b\n" "${GREEN}Selected: $selected_path${RC}"
}

# Main selection function that chooses the appropriate method
select_path() {
    if check_terminal_capabilities; then
        select_path_interactive
    else
        select_path_numbered
    fi
}

# Function to prepare paths for selection
prepare_path_selection() {
    input_paths="$1"
    paths_string=""
    total=0
    
    # Create a clean array of paths, filtering out any invalid entries
    if [ -n "$input_paths" ]; then
        IFS='
'
        for path in $input_paths; do
            # Clean the path and validate it
            clean_path=$(echo "$path" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Only include if it's a valid directory path
            if [ -n "$clean_path" ] && [ -d "$clean_path" ]; then
                if [ $total -eq 0 ]; then
                    paths_string="$clean_path"
                else
                    paths_string="$paths_string|$clean_path"
                fi
                total=$((total + 1))
            fi
        done
        IFS=' '
    fi
    
    # Ensure we have at least one valid path
    if [ $total -eq 0 ]; then
        printf "%b\n" "${RED}No valid paths found for selection.${RC}"
        return 1
    fi
    
    selected=0
    return 0
}

# Main execution starts here
find_steamapps_dirs
if [ $? -ne 0 ]; then
    printf "%b\n" "${RED}Cannot proceed without Steam library folders.${RC}"
    exit 1
fi


# Get compatdata paths
compatdata_paths=$(find_compatdata_paths)
prepare_path_selection "$compatdata_paths"
menu_title="Please select the compatdata path (for game settings):"
select_path
compatdata_path="$selected_path"

# Validate compatdata path
if [ ! -d "$compatdata_path" ]; then
    printf "%b\n" "${RED}The specified compatdata path does not exist.${RC}"
    exit 1
fi

# Get common game paths
common_paths=$(find_common_paths)
# Select common game path
prepare_path_selection "$common_paths"
menu_title="Please select the common game installation path:"
select_path
common_game_path="$selected_path"

# Validate common game path
if [ ! -d "$common_game_path" ]; then
    printf "%b\n" "${RED}The specified common game path does not exist.${RC}"
    exit 1
fi

printf "%b\n" "${GREEN}Selected paths:${RC}"
printf "%b\n" "  Compatdata path: $compatdata_path"
printf "%b\n" "  Common game path: $common_game_path"

if [ -d "/tmp/fallout76-configs" ]; then
    rm -rf /tmp/fallout76-configs
fi

printf "%b\n" "${YELLOW}Cloning the latest custom settings and mods...${RC}"
if ! git clone https://github.com/ChrisTitusTech/fallout76-configs /tmp/fallout76-configs; then
    printf "%b\n" "${RED}Failed to clone repository.${RC}"
    exit 1
fi

# Install settings to compatdata path
if [ -f "/tmp/fallout76-configs/Fallout76Custom.ini" ]; then
    mv /tmp/fallout76-configs/Fallout76Custom.ini "$compatdata_path/Fallout76Custom.ini"
    printf "%b\n" "${GREEN}Settings file installed successfully.${RC}"
else
    printf "%b\n" "${YELLOW}Warning: Fallout76Custom.ini not found in repository.${RC}"
fi

# Install mods to common game path
if [ -d "/tmp/fallout76-configs/mods" ]; then
    # Use rsync for proper recursive copying/merging, fallback to cp if rsync not available
    if command_exists "rsync"; then
        rsync -av /tmp/fallout76-configs/mods/ "$common_game_path/"
    else
        cp -rf /tmp/fallout76-configs/mods/* "$common_game_path/" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Mods installed successfully to common game path.${RC}"
else
    printf "%b\n" "${YELLOW}Warning: No mods directory found in repository.${RC}"
fi

# Clean up temporary files
rm -rf /tmp/fallout76-configs

printf "%b\n" "${GREEN}Settings installed successfully to compatdata path.${RC}"
printf "%b\n" "${GREEN}Common game path used for mods: $common_game_path${RC}"
