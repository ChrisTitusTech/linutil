#!/bin/sh -e

. ../common-script.sh

installAutoCpufreq() {
    clear
    printf "%b\n" "${YELLOW}Checking if auto-cpufreq is already installed...${RC}"

    # Check if auto-cpufreq is already installed
    if command_exists auto-cpufreq; then
        printf "%b\n" "${GREEN}auto-cpufreq is already installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing auto-cpufreq...${RC}"

        # Install git if not already installed
        if ! command_exists git; then
            printf "%b\n" "${YELLOW}git not found. Installing git...${RC}"
            case "$PACKAGER" in
                pacman)
                    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm git
                    ;;
                apk)
                    "$ESCALATION_TOOL" "$PACKAGER" add git
                    ;;
                *)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y git
                    ;;
            esac
        fi

        # Clone the auto-cpufreq repository and run the installer
        if [ ! -d "auto-cpufreq" ]; then
            printf "%b\n" "${YELLOW}Cloning auto-cpufreq repository...${RC}"
            git clone https://github.com/AdnanHodzic/auto-cpufreq.git
        fi

        cd auto-cpufreq
        printf "%b\n" "${YELLOW}Running auto-cpufreq installer...${RC}"
        "$ESCALATION_TOOL" ./auto-cpufreq-installer
        "$ESCALATION_TOOL"  auto-cpufreq --install

        cd ..
    fi
}

configureAutoCpufreq() {
    printf "%b\n" "${YELLOW}Configuring auto-cpufreq...${RC}"

    if command_exists auto-cpufreq; then
        # Check if the system has a battery to determine if it's a laptop
        if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
            printf "%b\n" "${GREEN}System detected as laptop. Updating auto-cpufreq for laptop...${RC}"
            "$ESCALATION_TOOL" auto-cpufreq --force powersave
        else
            printf "%b\n" "${GREEN}System detected as desktop. Updating auto-cpufreq for desktop...${RC}"
            "$ESCALATION_TOOL" auto-cpufreq --force performance
        fi
    else
        printf "%b\n" "${RED}auto-cpufreq is not installed, skipping configuration.${RC}"
    fi
}

removeAutoCpufreqTweak() {
    printf "%b\n" "${YELLOW}Removing auto-cpufreq tweak...${RC}"

    if command_exists auto-cpufreq; then
        printf "%b\n" "${YELLOW}Resetting auto-cpufreq configuration...${RC}"
        "$ESCALATION_TOOL" auto-cpufreq --force reset
    else
        printf "%b\n" "${RED}auto-cpufreq is not installed, skipping removal.${RC}"
    fi
}

apply_or_remove_auto_cpufreq() {
    # Prompt user for action
    printf "%b\n" "${YELLOW}Do you want to apply the auto-cpufreq tweak or remove it?${RC}"
    printf "%b\n" "${YELLOW}1) Apply tweak${RC}"
    printf "%b\n" "${YELLOW}2) Remove tweak${RC}"
    printf "%b" "Enter your choice [1/2]: "
    read -r choice

    case $choice in
        1)
            configureAutoCpufreq
            ;;
        2)
            removeAutoCpufreqTweak
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
apply_or_remove_auto_cpufreq
