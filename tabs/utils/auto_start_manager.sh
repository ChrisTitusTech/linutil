#!/bin/sh -e

# Directories for application .desktop entries
SYSTEM_APPLICATION_DIRS="/usr/share/applications /usr/local/share/applications"
AUTOSTART_DIR="$HOME/.config/autostart"

# Ensure the autostart directory exists
mkdir -p "$AUTOSTART_DIR"

# Function to list all .desktop applications from system directories
list_all_desktop_apps() {
    echo "Available applications:"
    app_list=""

    for dir in $SYSTEM_APPLICATION_DIRS; do
        if [ -d "$dir" ]; then
            for file in "$dir"/*.desktop; do
                if [ -e "$file" ]; then
                    app_name=$(basename "$file" .desktop)
                    app_list="$app_list $app_name"
                    echo "- $app_name"
                fi
            done
        fi
    done

    if [ -z "$app_list" ]; then
        echo "No .desktop applications found in system directories."
    fi
}

# Function to add an application to autostart
add_autostart() {
    list_all_desktop_apps

    echo "Enter the name of the application to add to autostart (exact name): "
    read app_name
    desktop_file_path=""

    # Find the corresponding .desktop file for the application
    for dir in $SYSTEM_APPLICATION_DIRS; do
        if [ -f "$dir/$app_name.desktop" ]; then
            desktop_file_path="$dir/$app_name.desktop"
            break
        fi
    done

    if [ -z "$desktop_file_path" ]; then
        echo "No .desktop file found for $app_name."
        return
    fi

    # Copy the .desktop file to the autostart directory
    cp "$desktop_file_path" "$AUTOSTART_DIR/"
    echo "Autostart entry for $app_name added."
}

# Function to remove an application from autostart
remove_autostart() {
    echo "Enter the name of the application to remove from autostart: "
    read app_name

    desktop_file="$AUTOSTART_DIR/$app_name.desktop"

    if [ -f "$desktop_file" ]; then
        rm "$desktop_file"
        echo "Autostart entry for $app_name removed."
    else
        echo "No autostart entry found for $app_name."
    fi
}

# Function to list all autostart applications
list_autostart() {
    echo "Current autostart applications:"
    for file in "$AUTOSTART_DIR"/*.desktop; do
        if [ -e "$file" ]; then
            app_name=$(basename "$file" .desktop)
            echo "- $app_name"
        fi
    done
}

main(){
    while true; do
        clear
        echo "=========================================="
        echo " Auto Start Manager"
        echo "=========================================="
        echo "1. List all available .desktop applications"
        echo "2. Add an application to autostart"
        echo "3. Remove an application from autostart"
        echo "4. List all autostart applications"
        echo "5. Exit"
        echo "=========================================="
        echo "Enter your choice: "
        read choice

        case "$choice" in
            1) list_all_desktop_apps ;;
            2) add_autostart ;;
            3) remove_autostart ;;
            4) list_autostart ;;
            5) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac

        echo "Press [Enter] to continue..."
        read
    done
}

main