#!/bin/sh -e

. ../common-script.sh

installAutoCpufreq() {
    clear

    AUTO_CPUFREQ_PATH="$HOME/.local/share/auto-cpufreq"

    if ! command_exists auto-cpufreq; then
        printf "%b\n" "${YELLOW}Installing auto-cpufreq.${RC}"

        if ! command_exists git && [ "$PACKAGER" != "pacman" ]; then
            printf "%b\n" "${YELLOW}Installing git.${RC}"
            case "$PACKAGER" in
                *)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y git
                    ;;
            esac
        fi

        case "$PACKAGER" in
            pacman)
                if command_exists powerprofilesctl; then
                    printf "%b\n" "${YELLOW}Disabling powerprofilesctl service.${RC}"
                    "$ESCALATION_TOOL" systemctl disable --now power-profiles-daemon
                fi

                "$AUR_HELPER" -S --needed --noconfirm auto-cpufreq
                "$ESCALATION_TOOL" systemctl enable --now auto-cpufreq
                ;;
            *)
                mkdir -p "$HOME/.local/share"

                if [ -d "$AUTO_CPUFREQ_PATH" ]; then
                    rm -rf "$AUTO_CPUFREQ_PATH"
                fi

                printf "%b\n" "${YELLOW}Cloning auto-cpufreq repository.${RC}"
                git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$AUTO_CPUFREQ_PATH"

                cd "$AUTO_CPUFREQ_PATH"
                printf "%b\n" "${YELLOW}Running auto-cpufreq installer.${RC}"
                "$ESCALATION_TOOL" ./auto-cpufreq-installer
                "$ESCALATION_TOOL" auto-cpufreq --install
                ;;
        esac
    else
        printf "%b\n" "${GREEN}auto-cpufreq is already installed.${RC}"
    fi
}

applyTweak() {
    printf "%b\n" "${YELLOW}Configuring auto-cpufreq.${RC}"

    if command_exists auto-cpufreq; then
        if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}System detected as laptop. Updating auto-cpufreq for laptop.${RC}"
            "$ESCALATION_TOOL" auto-cpufreq --force powersave
        else
            printf "%b\n" "${GREEN}System detected as desktop. Updating auto-cpufreq for desktop.${RC}"
            "$ESCALATION_TOOL" auto-cpufreq --force performance
        fi
    else
        printf "%b\n" "${RED}auto-cpufreq is not installed.${RC}"
        exit 1
    fi
}

removeTweak() {
    if command_exists auto-cpufreq; then
        printf "%b\n" "${YELLOW}Removing auto-cpufreq tweak.${RC}"
        "$ESCALATION_TOOL" auto-cpufreq --force reset
    else
        printf "%b\n" "${RED}auto-cpufreq is not installed.${RC}"
        exit 1
    fi
}

main() {
    printf "%b\n" "${YELLOW}Do you want to apply the auto-cpufreq tweak or remove it?${RC}"
    printf "%b\n" "${YELLOW}1) Apply tweak${RC}"
    printf "%b\n" "${YELLOW}2) Remove tweak${RC}"
    printf "%b\n" "${YELLOW}3) Exit${RC}"
    printf "%b" "Enter your choice [1/3]: "
    read -r choice

    case "$choice" in
        1)
            applyTweak
            ;;
        2)
            removeTweak
            ;;
        3)
            printf "%b\n" "${GREEN}Exiting.${RC}"
            exit 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}auto-cpufreq setup complete.${RC}"
}

checkEnv
checkEscalationTool
installAutoCpufreq
main
