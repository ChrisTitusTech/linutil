#!/bin/sh -e

. ../common-script.sh

installLynis() {
    if command_exists lynis; then
        printf "%b\n" "${GREEN}Lynis is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Lynis...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lynis
            ;;
        apt-get | nala | dnf | eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y lynis
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -n install lynis
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add lynis
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy lynis
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac

    if ! command_exists lynis; then
        printf "%b\n" "${RED}Lynis installation failed.${RC}"
        exit 1
    fi
}

removeLynis() {
    printf "%b\n" "${YELLOW}Removing Lynis...${RC}"
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm lynis
            ;;
        apt-get | nala | dnf | eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" remove -y lynis
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -n remove lynis
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" del lynis
            ;;
        xbps-install)
            "$ESCALATION_TOOL" xbps-remove -Ry lynis
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;
    esac

    if command_exists lynis; then
        printf "%b\n" "${RED}Lynis removal failed.${RC}"
        exit 1
    fi

    printf "%b\n" "${GREEN}Lynis removed successfully.${RC}"
}

moveAuditResults() {
    AUDIT_LOG_SOURCE="/var/log/lynis.log"
    AUDIT_REPORT_SOURCE="/var/log/lynis-report.dat"

    if [ ! -f "$AUDIT_LOG_SOURCE" ] || [ ! -f "$AUDIT_REPORT_SOURCE" ]; then
        printf "%b\n" "${RED}Lynis audit log or report was not found in /var/log.${RC}"
        exit 1
    fi

    AUDIT_TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
    AUDIT_COUNTER=1

    while true; do
        AUDIT_LOG_DESTINATION="$HOME/lynis-${AUDIT_TIMESTAMP}-${AUDIT_COUNTER}.log"
        AUDIT_REPORT_DESTINATION="$HOME/lynis-report-${AUDIT_TIMESTAMP}-${AUDIT_COUNTER}.dat"

        if [ ! -e "$AUDIT_LOG_DESTINATION" ] && [ ! -L "$AUDIT_LOG_DESTINATION" ] &&
            [ ! -e "$AUDIT_REPORT_DESTINATION" ] && [ ! -L "$AUDIT_REPORT_DESTINATION" ]; then
            break
        fi

        AUDIT_COUNTER=$((AUDIT_COUNTER + 1))
    done

    "$ESCALATION_TOOL" mv "$AUDIT_LOG_SOURCE" "$AUDIT_LOG_DESTINATION"
    "$ESCALATION_TOOL" mv "$AUDIT_REPORT_SOURCE" "$AUDIT_REPORT_DESTINATION"
    "$ESCALATION_TOOL" chown "$(id -u):$(id -g)" "$AUDIT_LOG_DESTINATION" "$AUDIT_REPORT_DESTINATION"

    printf "\n%b\n" "${YELLOW}Audit log saved: ${AUDIT_LOG_DESTINATION}${RC}"
    printf "%b\n" "${YELLOW}Audit report saved: ${AUDIT_REPORT_DESTINATION}${RC}"
}

promptRemoval() {
    while true; do
        printf "\n%b\n" "${YELLOW}Remove Lynis?${RC}"
        printf "%b\n" "1 - Yes, Remove"
        printf "%b\n" "2 - No, Keep"
        printf "%b" "Enter your choice [1-2]: "

        if ! read -r choice; then
            printf "\n%b\n" "${RED}No choice received.${RC}"
            exit 1
        fi

        case "$choice" in
            1)
                removeLynis
                return 0
                ;;
            2)
                printf "%b\n" "${GREEN}Lynis kept installed.${RC}"
                return 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid choice. Enter 1 or 2.${RC}"
                ;;
        esac
    done
}

checkEnv
installLynis

printf "%b\n" "${YELLOW}Running: lynis audit system${RC}"
if ! "$ESCALATION_TOOL" lynis audit system; then
    printf "%b\n" "${RED}Lynis security audit failed.${RC}"
    exit 1
fi

moveAuditResults
promptRemoval
