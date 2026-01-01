#!/usr/bin/env bash
#!/usr/bin/env bash
#
# service-status.sh
#
# Prints the status of key services with icons.
# Requires: bash, systemctl
# Usage: /home/user/bin/service-status.sh
#
# Exit codes:
#   0 – Success
#   1 – Missing dependency or environment issue
#!/usr/bin/env bash
set -euo pipefail

USE_EMOJI=false
if [[ "$(locale charmap)" == "UTF-8" ]]; then
    USE_EMOJI=true
fi

get_icon() {
    local state="$1"
    if $USE_EMOJI; then
        case "$state" in
            active)      echo "✅";;
            inactive)    echo "⚪";;
            failed)      echo "❌";;
            activating)  echo "⏳";;
            deactivating)echo "⌛";;
            *)           echo "❓";;
        esac
    else
        case "$state" in
            active)      echo "✔";;
            inactive)    echo "o";;
            failed)      echo "x";;
            activating)  echo "~";;
            deactivating)echo "~";;
            *)           echo "?";;
        esac
    fi
}

if ! command -v systemctl >/dev/null; then
    printf "ERROR: systemctl not found; this script requires systemd.\n" >&2
    exit 1
fi

s1=$(systemctl is-active unbound 2>/dev/null || echo "<n/a>")
s2=$(systemctl is-active cloudflared 2>/dev/null || echo "<n/a>")
s3=$(systemctl is-active dnscrypt-proxy.service 2>/dev/null || echo "<n/a>")
s4=$(systemctl is-active obfuscation.service 2>/dev/null || echo "<n/a>")

# print everything on one aligned line
printf "	%-25s %-30s %-25s %-30s\n" \
    "$(get_icon "$s1") Unbound: $s1" \
    "$(get_icon "$s2") cloudflared: $s2" \
    "$(get_icon "$s3") dnscrypt: $s3" \
    "$(get_icon "$s4") obService: $s4"

log_info()  { printf "INFO:  %s\n" "$*" >&2; }
log_error() { printf "ERROR: %s\n" "$*" >&2; }
