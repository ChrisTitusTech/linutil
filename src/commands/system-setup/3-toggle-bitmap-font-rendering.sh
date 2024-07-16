#!/bin/bash

CONFIG_PATH="$HOME/.config/fontconfig/conf.d/20-no-embedded.conf"

configure_font_rendering() {
    if [ -f "$CONFIG_PATH" ]; then
        echo "Bitmap fonts are currently disabled."
        echo "Do you want to enable bitmap fonts? (This will remove the configuration file)"
        read -p "Press Enter to enable, or any other key to cancel: " -n 1 -s response
        echo  # Move to a new line
        if [ -z "$response" ]; then
            if rm -f "$CONFIG_PATH"; then
                echo "Font rendering configuration reverted successfully."
                echo "Embedded bitmaps have been enabled for all fonts."
                echo "Please restart your session to apply the changes."
            else
                echo "Error: Failed to remove the configuration file."
            fi
        else
            echo "Operation cancelled. Bitmap fonts remain disabled."
        fi
    else
        echo "Bitmap fonts are currently enabled (default setting)."
        echo "Do you want to disable bitmap fonts? (This will create a configuration file)"
        read -p "Press Enter to disable, or any other key to cancel: " -n 1 -s response
        echo  # Move to a new line
        if [ -z "$response" ]; then
            mkdir -p "$(dirname "$CONFIG_PATH")"
            cat <<EOL > "$CONFIG_PATH"
<match target="font">
  <edit name="embeddedbitmap" mode="assign">
    <bool>false</bool>
  </edit>
</match>
EOL
            if [ $? -eq 0 ]; then
                echo "Font rendering configuration updated successfully."
                echo "Embedded bitmaps have been disabled for all fonts to improve font rendering quality."
                echo "Please restart your session to apply the changes."
            else
                echo "Error: Failed to create the configuration file."
            fi
        else
            echo "Operation cancelled. Bitmap fonts remain enabled."
        fi
    fi
}

if [ ! -w "$HOME" ]; then
    echo "Home directory is not writable. Please check your permissions."
    exit 1
fi

configure_font_rendering