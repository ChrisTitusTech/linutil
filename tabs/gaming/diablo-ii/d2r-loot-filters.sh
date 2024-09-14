#!/bin/bash

# Search for possible Diablo II Resurrected folder locations
echo "Searching for Diablo II Resurrected folders..."
possible_paths=$(find $HOME -type d -path "*/drive_c/Program Files (x86)/Diablo II Resurrected" 2>/dev/null)

if [ -z "$possible_paths" ]; then
    echo "Error: No Diablo II Resurrected folders found."
    exit 1
fi

# Display possible paths and allow selection
echo "Possible Diablo II Resurrected folder locations:"
mapfile -t paths_array <<< "$possible_paths"
selected=0
total=${#paths_array[@]}

print_menu() {
    clear
    local max_display=$((total < 10 ? total : 10))
    local start=$((selected - max_display/2))
    if ((start < 0)); then start=0; fi
    if ((start + max_display > total)); then start=$((total - max_display)); fi
    if ((start < 0)); then start=0; fi
    
    echo "Please select the Diablo II: Resurrected installation path:"
    for i in $(seq 0 $((max_display - 1))); do
        if ((i + start >= total)); then break; fi
        if [ $((i + start)) -eq $selected ]; then
            echo "> ${paths_array[$((i + start))]}"
        else
            echo "  ${paths_array[$((i + start))]}"
        fi
    done
}

select_path() {
    local last_selected=-1

    while true; do
        if [ $last_selected -ne $selected ]; then
            print_menu
            last_selected=$selected
        fi

        read -rsn1 key
        case "$key" in
            $'\x1B')  # ESC key
                read -rsn2 key
                case "$key" in
                    '[A' | 'k')
                        if ((selected > 0)); then
                            ((selected--))
                        fi
                        ;;
                    '[B' | 'j')
                        if ((selected < total - 1)); then
                            ((selected++))
                        fi
                        ;;
                esac
                ;;
            '')  # Enter key
                d2r_path="${paths_array[$selected]}"
                break
                ;;
        esac
    done

    clear  # Clear the screen after selection
}

# Use the select_path function
select_path

# Validate the path
if [ ! -d "$d2r_path" ]; then
    echo "Error: The specified path does not exist."
    exit 1
fi

# Create the mods folder if it doesn't exist
mods_path="$d2r_path/mods"
mkdir -p "$mods_path"

# Download the latest release
echo "Downloading the latest loot filter..."
wget -q --show-progress https://github.com/ChrisTitusTech/d2r-loot-filter/releases/latest/download/lootfilter.zip -O /tmp/lootfilter.zip

# Extract the contents to the mods folder
echo "Extracting loot filter to $mods_path..."
unzip -q -o /tmp/lootfilter.zip -d "$mods_path"

# Clean up
rm /tmp/lootfilter.zip

echo "Loot filter installed successfully in $mods_path"

# Add instructions for setting launch options
echo
echo "To complete the setup, please follow these steps to add launch options in Battle.net:"
echo "1. Open the Battle.net launcher"
echo "2. Select Diablo II: Resurrected"
echo "3. Click the gear icon next to the 'Play' button"
echo "4. Select 'Game Settings'"
echo "5. In the 'Additional command line arguments' field, enter: -mod lootfilter -txt"
echo "6. Click 'Done' to save the changes"
echo
echo "After completing these steps, launch Diablo II: Resurrected through Battle.net to use the loot filter."