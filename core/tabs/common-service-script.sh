#!/bin/sh -e

checkInitManager() {
    for manager in $1; do
        if command_exists "$manager"; then
            INIT_MANAGER="$manager"
            printf "%b\n" "${CYAN}Using ${manager} to interact with init system${RC}"
            break
        fi
    done

    if [ -z "$INIT_MANAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported init system${RC}"
        exit 1
    fi
}

startService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" start "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" start
            ;;
        sv)
            "$ESCALATION_TOOL" sv start "$1"
            ;;
    esac
}

stopService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" stop "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" stop
            ;;
        sv)
            "$ESCALATION_TOOL" sv stop "$1"
            ;;
    esac
}

enableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" enable "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" rc-update add "$1"
            ;;
        sv)
            "$ESCALATION_TOOL" ln -sf "/etc/sv/$1" "/var/service/"
            printf "%b\n" "${YELLOW}Waiting 5 seconds...${RC}"
            sleep 5
            ;;
    esac
}

disableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" disable "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" rc-update del "$1"
            ;;
        sv)
            "$ESCALATION_TOOL" rm -f "/var/service/$1"
            ;;
    esac
}

startAndEnableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" enable --now "$1"
            ;;
        rc-service | sv)
            enableService "$1"
            startService "$1"
            ;;
    esac
}

isServiceActive() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" is-active --quiet "$1"
            ;;
        rc-service)
            "$ESCALATION_TOOL" "$INIT_MANAGER" "$1" status --quiet
            ;;
        sv)
            "$ESCALATION_TOOL" sv status "$1" >/dev/null 2>&1
            ;;
    esac
}

checkInitManager 'systemctl rc-service sv'
