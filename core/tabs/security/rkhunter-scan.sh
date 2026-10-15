#!/bin/sh -e

. ../common-script.sh

installRkhunter() {
    if command_exists rkhunter; then
        printf "%b\n" "${GREEN}rkhunter is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing rkhunter...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm rkhunter
            ;;
        apt-get | nala | dnf | eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y rkhunter
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -n install rkhunter
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add rkhunter
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy rkhunter
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac

    if ! command_exists rkhunter; then
        printf "%b\n" "${RED}rkhunter installation failed.${RC}"
        exit 1
    fi
}

removeRkhunter() {
    printf "%b\n" "${YELLOW}Removing rkhunter...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm rkhunter
            ;;
        apt-get | nala | dnf | eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" remove -y rkhunter
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -n remove rkhunter
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" del rkhunter
            ;;
        xbps-install)
            "$ESCALATION_TOOL" xbps-remove -Ry rkhunter
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac

    if command_exists rkhunter; then
        printf "%b\n" "${RED}rkhunter removal failed.${RC}"
        exit 1
    fi

    printf "%b\n" "${GREEN}rkhunter removed successfully.${RC}"
}

runScan() {
    SCAN_TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
    SCAN_COUNTER=1
    while true; do
        SCAN_LOG="$HOME/rkhunter-${SCAN_TIMESTAMP}-${SCAN_COUNTER}.log"
        if [ ! -e "$SCAN_LOG" ] && [ ! -L "$SCAN_LOG" ]; then
            break
        fi
        SCAN_COUNTER=$((SCAN_COUNTER + 1))
    done

    # Refresh the data files first. A failed update (for example, no network,
    # or the distro package disabling web downloads) must not abort the scan,
    # so do not let it trip 'set -e'.
    printf "%b\n" "${YELLOW}Updating rkhunter data files...${RC}"
    "$ESCALATION_TOOL" rkhunter --update || printf "%b\n" "${YELLOW}Data file update skipped or failed; continuing with existing data.${RC}"

    # rkhunter returns a non-zero status when it finds warnings, which is a
    # normal scan outcome rather than an execution error. Capture its real
    # exit status through the tee pipe and save the full report straight to
    # the user's home directory, independent of /var/log or syslog settings.
    STATUS_FILE=$(mktemp)
    printf "%b\n" "${YELLOW}Running: rkhunter --check --skip-keypress${RC}"
    # Disable 'set -e' only around the capture: rkhunter's non-zero warning
    # status must reach the status file instead of aborting the script, and
    # tee keeps the scan streaming live while the full report is written.
    set +e
    { "$ESCALATION_TOOL" rkhunter --check --skip-keypress; echo "$?" >"$STATUS_FILE"; } | tee "$SCAN_LOG"
    set -e
    SCAN_STATUS=$(cat "$STATUS_FILE")
    rm -f "$STATUS_FILE"

    # Exit status 0 (clean) and 1 (warnings found) both mean the scan ran. A
    # higher status, or an empty log, means rkhunter aborted before scanning,
    # which usually points to an invalid option in /etc/rkhunter.conf.
    if [ ! -s "$SCAN_LOG" ] || [ "$SCAN_STATUS" -gt 1 ]; then
        rm -f "$SCAN_LOG"
        printf "%b\n" "${RED}rkhunter did not complete a scan (exit status ${SCAN_STATUS}).${RC}"
        printf "%b\n" "${RED}This usually means /etc/rkhunter.conf contains an invalid option.${RC}"
        exit 1
    fi

    "$ESCALATION_TOOL" chown "$(id -u):$(id -g)" "$SCAN_LOG" 2>/dev/null || true
    printf "\n%b\n" "${YELLOW}Scan log saved: ${SCAN_LOG}${RC}"
    if [ "$SCAN_STATUS" -eq 1 ]; then
        printf "%b\n" "${YELLOW}rkhunter reported warnings. Review the log above.${RC}"
    else
        printf "%b\n" "${GREEN}rkhunter completed with no warnings.${RC}"
    fi
}

promptRemoval() {
    while true; do
        printf "\n%b\n" "${YELLOW}Remove rkhunter?${RC}"
        printf "%b\n" "1 - Yes, Remove"
        printf "%b\n" "2 - No, Keep"
        printf "%b" "Enter your choice [1-2]: "

        if ! read -r choice; then
            printf "\n%b\n" "${RED}No choice received.${RC}"
            exit 1
        fi

        case "$choice" in
            1)
                removeRkhunter
                return 0
                ;;
            2)
                printf "%b\n" "${GREEN}rkhunter kept installed.${RC}"
                return 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid choice. Enter 1 or 2.${RC}"
                ;;
        esac
    done
}

checkEnv
installRkhunter
runScan
promptRemoval
