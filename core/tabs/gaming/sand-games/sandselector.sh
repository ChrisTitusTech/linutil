#!/bin/sh -e

. ../../common-script.sh

DOWNLOAD_DIR="${HOME}/Downloads"

# Helper to open URLs
open_url() {
    url="$1"
    if command_exists xdg-open; then
        xdg-open "$url"
        printf "%b\n" "${GREEN}✓ Opened in your default browser.${RC}"
    else
        printf "%b\n" "${YELLOW}Please open this URL manually:${RC}"
        printf "%b\n" "  $url"
    fi
}

launchFallingSand() {
    printf "%b\n" "${CYAN}Launching - Falling Sand (Project Sand)...${RC}"
    printf "%b\n" "${YELLOW}A classic physics sandbox — draw with elements!${RC}"
    open_url "https://www.projectsand.io/"
}
    
launchPowderGame() {
    printf "%b\n" "${CYAN}Launching - Dan-Ball: Powder Game (Dust2)...${RC}"
    printf "%b\n" "${YELLOW}Remake of 'Powder Game' - Introduces more realistic physics engine.${RC}"
    open_url "https://dan-ball.jp/en/javagame/dust2/"
}
    
launchPowderToy() {
    printf "%b\n" "${CYAN}Launching - The Powder Toy...${RC}"
    printf "%b\n" "${YELLOW}A free physics sandbox, which simulates interactions between different substances!${RC}"
    open_url "https://powdertoy.co.uk/Wasm.html"
}
    
launchThisIsSand() {
    printf "%b\n" "${CYAN}Launching - ThisIsSand...${RC}"
    printf "%b\n" "${YELLOW}Playable on 'laptop/desktop' web-browser (thisissand.com) OR 'Thisissand' app (iOS/Android)${RC}"
    open_url "https://thisissand.com/"
}
    
launchSandSaga() {
    printf "%b\n" "${CYAN}Launching - Sand Saga (sandbox)...${RC}"
    printf "%b\n" "${YELLOW}Fast & powerful falling-sand game that allows players to experiment with various elements.${RC}"
    open_url "https://sandsaga.com/s/sandbox"
}
    
zipSecretBonus() {
    printf "%b\n" "${CYAN}Zipping 🔒5Days...${RC}"
    printf "%b\n" "${YELLOW}❓❓❓${RC}"
    mkdir -p "$DOWNLOAD_DIR/5Days"
    cd "$DOWNLOAD_DIR" || return 1
    
    printf "%b\n" "${YELLOW}Downloading Zip...(this will only take a second)${RC}"
    if curl -L -s -o "5days13.zip" "http://www.clawofcat.com/yahtzee/5days13.zip"; then
        printf "%b\n" "${GREEN}✓ Download complete! Extracting...${RC}"
        unzip -q -o "5days13.zip" -d "$DOWNLOAD_DIR/5Days"
        rm "5days13.zip"
        printf "%b\n" "${GREEN}✓ Unzipped to: $DOWNLOAD_DIR/5Days${RC}"
    else
        printf "%b\n" "${RED}Download failed.${RC}"
        return 1
    fi
}

show_menu() {
    printf "%b\n" "${CYAN}======================================${RC}"
    printf "                    SandEngine Game Selector\n"
    printf "%b\n" "${CYAN}======================================${RC}"
    printf "1) FallingSand\n"
    printf "2) PowderGame\n"
    printf "3) PowderToy\n"
    printf "4) ThisIsSand\n"
    printf "5) SandSaga\n"
    printf "6) SECRET BONUS ❓❓❓ (Download)\n"
    printf "0) Cancel\n"
    
    printf "%b" "${YELLOW}Select [0-6]: ${RC}"
    read -r choice

    case "$choice" in
        1) launchFallingSand ; exit 0 ;;
        2) launchPowderGame ; exit 0 ;;
        3) launchPowderToy ; exit 0 ;;
        4) launchThisIsSand ; exit 0 ;;
        5) launchSandSaga ; exit 0 ;;
        6) zipSecretBonus ; exit 0 ;;
        0) printf "Exiting...\n" ; exit 0 ;;
        *) printf "%b\n" "${RED}Invalid selection.${RC}" ; show_menu ;;
    esac
}

# --- Main Execution ---
checkArch
checkCommandRequirements "curl" "unzip"
show_menu