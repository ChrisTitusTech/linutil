#!/bin/sh -e

. ../common-script.sh

setupAudio() {
    if systemctl --user is-active --quiet pipewire; then
        audio_server="pipewire"
    elif systemctl --user is-active --quiet pulseaudio; then
        audio_server="pulseaudio"
    else
        clear
        printf "%b\n" "${YELLOW}Pick an Audio Server${RC}"
        printf "%b\n" "1. PulseAudio"
        printf "%b\n" "2. PipeWire"
        printf "%b" "Choose an option: "
        read -r choice

        case $choice in
            1) audio_server="pulseaudio" ;;
            2) audio_server="pipewire pipewire-pulse" ;;
            *) return ;;
        esac

        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$audio_server"
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$audio_server"
                ;;
        esac
    fi
}

menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}Audio Manager${RC}"
        printf "%b\n" "${YELLOW}=============${RC}"
        printf "%b\n" "1. Mute Audio"
        printf "%b\n" "2. Unmute Audio"
        printf "%b\n" "3. Set Volume"
        printf "%b\n" "4. List Current Volume"
        printf "%b" "Choose an option: "
        read -r choice

        case $choice in
            1) muteAudio ;;
            2) unmuteAudio ;;
            3) setVolume ;;
            4) listVolume ;;
            *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
        esac
    done
}

muteAudio() {
    clear
    if pactl set-sink-mute @DEFAULT_SINK@ toggle; then
        printf "%b\n" "${GREEN}Audio muted.${RC}"
    else
        printf "%b\n" "${RED}Failed to mute audio.${RC}"
    fi
    printf "%b\n" "Press enter to return to the main menu..."
    read -r dummy
}

unmuteAudio() {
    clear
    if pactl set-sink-mute @DEFAULT_SINK@ toggle; then
        printf "%b\n" "${GREEN}Audio unmuted.${RC}"
    else
        printf "%b\n" "${RED}Failed to unmute audio.${RC}"
    fi
    printf "%b\n" "Press enter to return to the main menu..."
    read -r dummy
}

setVolume() {
    while true; do
        clear
        printf "%b" "Enter the volume percentage (1-100): "
        read -r volume
        if [ "$volume" -ge 1 ] && [ "$volume" -le 100 ]; then
            if pactl set-sink-volume @DEFAULT_SINK@ "$volume%"; then
                printf "%b\n" "${GREEN}Volume set to $volume% successfully.${RC}"
            else
                printf "%b\n" "${RED}Failed to set volume.${RC}"
            fi
            break
        else
            printf "%b\n" "${RED}Invalid volume percentage.${RC}"
            printf "%b\n" "Press enter to try again..."
            read -r dummy
        fi
    done
    printf "%b\n" "Press enter to return to the main menu..."
    read -r dummy
}

listVolume() {
    clear
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)
    printf "%b\n" "${YELLOW}Current volume: $volume${RC}"
    printf "%b\n" "Press enter to return to the main menu..."
    read -r dummy
}

checkEnv
checkEscalationTool
setupAudio
menu