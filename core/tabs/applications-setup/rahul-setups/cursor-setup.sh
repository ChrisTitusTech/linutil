#!/bin/sh -e

. ../../common-script.sh



installCursor() {
    if ! [ -f /opt/cursor.appimage ]; then
        printf "%b\n" "${YELLOW}Installing Cursor AI IDE..${RC}."
        CURSOR_URL="https://www.cursor.com/_next/image?url=%2Fassets%2Fimages%2Flogo.png&w=48&q=75"
        #ICON_URL="https://www.trycursor.com/assets/logo.png" # official icon
        ICON_URL="https://raw.githubusercontent.com/rahuljangirwork/copmany-logos/refs/heads/main/cursor.png" # Replace if you have a specific URLhttps://www.cursor.com/_next/image?url=%2Fassets%2Fimages%2Flogo.png&w=48&q=75

        APPIMAGE_PATH="/opt/cursor.appimage"
        ICON_PATH="/opt/cursor.png"
        DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"

        # Download Cursor AppImage
        curl -L $CURSOR_URL -o $APPIMAGE_PATH
        chmod +x $APPIMAGE_PATH

        # Download Cursor icon
        curl -L $ICON_URL -o $ICON_PATH

        # Create a .desktop entry for Cursor
        printf "%b\n" "${YELLOW}Creating .desktop entry for Cursor..${RC}."
        sudo bash -c "cat > $DESKTOP_ENTRY_PATH" <<EOL
[Desktop Entry]
Name=Cursor
Exec=$APPIMAGE_PATH
Icon=$ICON_PATH
Type=Application
Categories=Development;
EOL
    else
        printf "%b\n" "${GREEN}Cursor AI IDE is already installed.${RC}"
    fi
}






checkEnv
checkEscalationTool
checkAURHelper

installCursor

