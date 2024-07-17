#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

CONFIG_PATH="$HOME/.config/fontconfig/conf.d/20-no-embedded.conf"

read_key() {
    stty -echo -icanon time 0 min 1
    dd bs=1 count=1 2>/dev/null
    stty echo icanon
}

configure_font_rendering() {
    if [ -f "$CONFIG_PATH" ]; then
        printf "${YELLOW}Bitmap fonts are currently disabled.${RC}\n"
        echo "Do you want to enable bitmap fonts? (This will remove the configuration file)"
        printf "Press Enter to enable, or any other key to cancel: "
        key=$(read_key)
        if [ "$key" = "" ]; then
            if rm -f "$CONFIG_PATH"; then
                printf "\n${GREEN}SUCCESS!${RC}\n\n"
                printf "${GREEN}Font rendering configuration reverted successfully.${RC}\n"
                echo "Embedded bitmaps have been enabled for all fonts."
                echo "Please restart your session to apply the changes."
            else
                printf "${RED}Error: Failed to remove the configuration file.${RC}\n"
            fi
        else
            echo "Operation cancelled. Bitmap fonts remain disabled."
        fi
    else
        printf "${YELLOW}Bitmap fonts are currently enabled (default setting).${RC}\n"
        echo "Do you want to disable bitmap fonts? (This will create a configuration file)"
        printf "Press Enter to disable, or any other key to cancel: "
        key=$(read_key)
        if [ "$key" = "" ]; then
            mkdir -p "$(dirname "$CONFIG_PATH")"
            cat <<EOL > "$CONFIG_PATH"
<match target="font">
  <edit name="embeddedbitmap" mode="assign">
    <bool>false</bool>
  </edit>
</match>
EOL
            if [ $? -eq 0 ]; then
                printf "\n${GREEN}SUCCESS!${RC}\n\n"
                printf "${GREEN}Font rendering configuration updated successfully.${RC}\n"
                echo "Embedded bitmaps have been disabled for all fonts to improve font rendering quality."
                echo "Please restart your session to apply the changes."
            else
                printf "${RED}Error: Failed to create the configuration file.${RC}\n"
            fi
        else
            echo "Operation cancelled. Bitmap fonts remain enabled."
        fi
    fi
}


if [ ! -w "$HOME" ]; then
    printf "${RED}Home directory is not writable. Please check permissions.${RC}\n"
    exit 1
fi

configure_font_rendering