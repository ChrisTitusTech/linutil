#!/bin/sh -e

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "Directory $1 does not exist. Please enter a valid directory."
        exit 1
    fi
}

# Function to organize files by type
organize_by_type() {
    TARGET_DIR="$1"

    echo "Organizing files in $TARGET_DIR by type..."

    for file in "$TARGET_DIR"/*; do
        if [ -f "$file" ]; then
            EXT=$(echo "$file" | sed 's/.*\.//')
            if [ -z "$EXT" ]; then
                EXT="no_extension"
            fi
            mkdir -p "$TARGET_DIR/$EXT"
            mv "$file" "$TARGET_DIR/$EXT/"
        fi
    done

    echo "Files organized by type."
}

# Function to organize files by date
organize_by_date() {
    TARGET_DIR="$1"

    echo "Organizing files in $TARGET_DIR by date..."

    for file in "$TARGET_DIR"/*; do
        if [ -f "$file" ]; then
            DATE=$(date -r "$file" "+%Y-%m-%d")
            mkdir -p "$TARGET_DIR/$DATE"
            mv "$file" "$TARGET_DIR/$DATE/"
        fi
    done

    echo "Files organized by date."
}

# Function to prompt user for input and call the appropriate function
interactive_menu() {
    echo "Welcome to the File Organizer Script"
    echo "Enter the directory path to organize:"
    read TARGET_DIR

    check_directory "$TARGET_DIR"

    echo "Choose how to organize files:"
    echo "1. By type (e.g., .jpg, .txt)"
    echo "2. By date (e.g., 2024-09-15)"
    echo "Enter your choice (1 or 2):"
    read choice

    case "$choice" in
        1)
            organize_by_type "$TARGET_DIR"
            ;;
        2)
            organize_by_date "$TARGET_DIR"
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            exit 1
            ;;
    esac
}

# Main script execution
interactive_menu
