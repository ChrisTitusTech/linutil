#!/bin/sh -e

. ../../common-script.sh

# Check for required commands
for cmd in find curl unzip stty; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "%b\n" "Error: $cmd is not installed."
        exit 1
    fi
done

# Search for possible Diablo II Resurrected folder locations
printf "%b\n" "Searching for Diablo II Resurrected folders..."
possible_paths=$(find "$HOME" -type d -path "*/drive_c/Program Files (x86)/Diablo II Resurrected" 2>/dev/null)

if [ -z "$possible_paths" ]; then
    printf "%b\n" "Error: No Diablo II Resurrected folders found."
    exit 1
fi

# Display possible paths and allow selection
printf "%b\n" "Possible Diablo II Resurrected folder locations:"
paths_string=""
i=0
IFS='
'
for path in $possible_paths; do
    paths_string="$paths_string|$path"
    i=$((i + 1))
done
IFS=' '
paths_string="${paths_string#|}"
total=$i
selected=0

print_menu() {
    command -v clear >/dev/null 2>&1 && clear
    max_display=$((total < 10 ? total : 10))
    start=$((selected - max_display / 2))
    if [ $start -lt 0 ]; then start=0; fi
    if [ $((start + max_display)) -gt $total ]; then start=$((total - max_display)); fi
    if [ $start -lt 0 ]; then start=0; fi
    
    printf "%b\n" "Please select the Diablo II: Resurrected installation path:"
    i=0
    echo "$paths_string" | tr '|' '\n' | while IFS= read -r path; do
        if [ $i -ge $start ] && [ $i -lt $((start + max_display)) ]; then
            if [ $i -eq $selected ]; then
                printf "> %s\n" "$path"
            else
                printf "  %s\n" "$path"
            fi
        fi
        i=$((i + 1))
    done
}

select_path() {
    last_selected=-1

    while true; do
        if [ $last_selected -ne $selected ]; then
            print_menu
            last_selected=$selected
        fi

        stty -echo
        key=$(dd bs=1 count=1 2>/dev/null)
        stty echo

        case "$key" in
            $(printf '\033')A | k)
                if [ $selected -gt 0 ]; then
                    selected=$((selected - 1))
                fi
                ;;
            $(printf '\033')B | j)
                if [ $selected -lt $((total - 1)) ]; then
                    selected=$((selected + 1))
                fi
                ;;
            '')
                d2r_path=$(echo "$paths_string" | cut -d '|' -f $((selected + 1)))
                break
                ;;
        esac
    done

    command -v clear >/dev/null 2>&1 && clear
}

# Use the select_path function
select_path

# Validate the path
if [ ! -d "$d2r_path" ]; then
    printf "%b\n" "Error: The specified path does not exist."
    exit 1
fi

# Create the mods folder if it doesn't exist
mods_path="$d2r_path/mods"
mkdir -p "$mods_path"

# Download the latest release
printf "%b\n" "Downloading the latest loot filter..."
if ! curl -sSLo /tmp/lootfilter.zip https://github.com/ChrisTitusTech/d2r-loot-filter/releases/latest/download/lootfilter.zip; then
    printf "%b\n" "Error: Failed to download the loot filter."
    exit 1
fi

# Extract the contents to the mods folder
printf "%b\n" "Extracting loot filter to $mods_path..."
if ! unzip -q -o /tmp/lootfilter.zip -d "$mods_path"; then
    printf "%b\n" "Error: Failed to extract the loot filter."
    exit 1
fi

# Clean up
rm /tmp/lootfilter.zip

printf "%b\n" "Loot filter installed successfully in $mods_path"

printf "\nTo complete the setup, please follow these steps to add launch options in Battle.net:\n"
printf "1. Open the Battle.net launcher\n"
printf "2. Select Diablo II: Resurrected\n"
printf "3. Click the gear icon next to the 'Play' button\n"
printf "4. Select 'Game Settings'\n"
printf "5. In the 'Additional command line arguments' field, enter: -mod lootfilter -txt\n"
printf "6. Click 'Done' to save the changes\n"
printf "\nAfter completing these steps, launch Diablo II: Resurrected through Battle.net to use the loot filter.\n"