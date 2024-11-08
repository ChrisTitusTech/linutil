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
    esac
}

startAndEnableService() {
    case "$INIT_MANAGER" in
        systemctl)
            "$ESCALATION_TOOL" "$INIT_MANAGER" enable --now "$1"
            ;;
        rc-service)
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
    esac
}

checkInitManager 'systemctl rc-service'