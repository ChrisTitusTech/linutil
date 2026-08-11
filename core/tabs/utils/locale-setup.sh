#!/bin/sh -e
. ../common-script.sh

setLocale() {
    if command_exists locale-gen; then
        iso=$(curl -4fsSL --max-time 5 https://ifconfig.io/country_code 2>/dev/null) || iso="US"
        supported_locales=$(awk '$2 == "UTF-8" { print $1 }' /usr/share/i18n/SUPPORTED)
        suggested_locales=$(printf '%s\n' "$supported_locales" | grep -iE "(^|_)${iso}([.@]|$)" || true)

        if [ -z "$suggested_locales" ]; then
            suggested_locales=$supported_locales
        fi

        printf "%s\n" "Suggested locales based on your location ($iso):"
        i=1
        for loc in $suggested_locales; do
            printf "  %d) %s\n" "$i" "$loc"
            i=$((i + 1))
        done
        printf "  %s\n" "c) Enter a custom locale"

        printf "%s" "Select a locale number (or 'c' for custom): "
        read -r choice

        if [ "$choice" = "c" ] || [ "$choice" = "C" ]; then
            LOCALE=""
            while [ -z "$LOCALE" ]; do
                printf "%s" "Enter locale (e.g. en_US): "
                read -r custom_locale

                if [ -z "$custom_locale" ]; then
                    printf "%s\n" "Locale cannot be empty."
                    continue
                fi

                if [ "$custom_locale" = "C.UTF-8" ] || printf '%s\n' "$supported_locales" | grep -qxF "$custom_locale"; then
                    LOCALE="$custom_locale"
                else
                    printf "%s\n" "'$custom_locale' is not a recognized locale. Please try again."
                fi
            done
        else
            case "$choice" in
                ''|0|*[!0-9]*)
                    printf "%s\n" "Invalid selection."
                    exit 1
                    ;;
            esac
            LOCALE=$(printf "%s\n" "$suggested_locales" | sed -n "${choice}p")
            if [ -z "$LOCALE" ]; then
                printf "%s\n" "Invalid selection."
                exit 1
            fi
        fi

        if ! grep -qxF "${LOCALE} UTF-8" /etc/locale.gen 2>/dev/null; then
            printf '%s UTF-8\n' "$LOCALE" | "$ESCALATION_TOOL" tee -a /etc/locale.gen >/dev/null
        fi
        if grep -q '^LANG=' /etc/locale.conf 2>/dev/null; then
            "$ESCALATION_TOOL" sed -i "s/^LANG=.*/LANG=${LOCALE}/" /etc/locale.conf
        else
            printf 'LANG=%s\n' "$LOCALE" | "$ESCALATION_TOOL" tee -a /etc/locale.conf >/dev/null
        fi
        "$ESCALATION_TOOL" locale-gen "${LOCALE}"
    else
        printf "%b\n" "ERROR! locale-gen not found; cannot generate locales on this system."
        exit 1
    fi
}

checkEnv
setLocale
