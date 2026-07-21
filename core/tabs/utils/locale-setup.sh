#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

get_suggested_locale() {
    key="$1"
    default_locale="en_US.UTF-8"

    # Use case statement to map keys to values (POSIX standard)
    case "$key" in
        us) printf "%b" "en_US.UTF-8" ;;
        ca) printf "%b" "en_CA.UTF-8" ;;
        cn) printf "%b" "zh_CN.UTF-8" ;;
        by) printf "%b" "be_BY.UTF-8" ;;
        ch) printf "%b" "de_CH.UTF-8" ;;
        cz) printf "%b" "cs_CZ.UTF-8" ;;
        de) printf "%b" "de_DE.UTF-8" ;;
        dk) printf "%b" "da_DK.UTF-8" ;;
        es) printf "%b" "es_ES.UTF-8" ;;
        et) printf "%b" "et_EE.UTF-8" ;;
        fa) printf "%b" "fa_IR.UTF-8" ;;
        fi) printf "%b" "fi_FI.UTF-8" ;;
        fr) printf "%b" "fr_FR.UTF-8" ;;
        gb) printf "%b" "en_GB.UTF-8" ;;
        gr) printf "%b" "el_GR.UTF-8" ;;
        hu) printf "%b" "hu_HU.UTF-8" ;;
        il) printf "%b" "he_IL.UTF-8" ;;
        it) printf "%b" "it_IT.UTF-8" ;;
        jp) printf "%b" "ja_JP.UTF-8" ;;
        kr) printf "%b" "ko_KR.UTF-8" ;;
        lt) printf "%b" "lt_LT.UTF-8" ;;
        lv) printf "%b" "lv_LV.UTF-8" ;;
        mk) printf "%b" "mk_MK.UTF-8" ;;
        nl) printf "%b" "nl_NL.UTF-8" ;;
        no) printf "%b" "nb_NO.UTF-8" ;;
        ph) printf "%b" "en_PH.UTF-8" ;;
        pl) printf "%b" "pl_PL.UTF-8" ;;
        ro) printf "%b" "ro_RO.UTF-8" ;;
        ru) printf "%b" "ru_RU.UTF-8" ;;
        se) printf "%b" "sv_SE.UTF-8" ;;
        sg) printf "%b" "en_SG.UTF-8" ;;
        si) printf "%b" "sl_SI.UTF-8" ;;
        tr) printf "%b" "tr_TR.UTF-8" ;;
        ua) printf "%b" "uk_UA.UTF-8" ;;
        *) printf "%b" "$default_locale" ;; # Default fallback
    esac
}

setLocale() {
    if command_exists locale-gen; then

        iso=$(curl -4fsSL --max-time 5 https://ifconfig.io/country_code 2>/dev/null | tr '[:upper:]' '[:lower:]') || iso="us"
        suggested_locale=$(get_suggested_locale "${iso}")

        while true; do
            printf "Detected locale: '%s'. Press Enter to accept or type a new one (e.g. de_DE.UTF-8): " "$suggested_locale"
            read -r input
            LOCALE="${input:-$suggested_locale}"

            case "$LOCALE" in
                *[![:alnum:]_.@-]*|'') ;;
                *.UTF-8) break ;;
            esac

            # If we reach here, the validation failed
            printf "ERROR! Locale '%s' does not look valid. Please enter a locale like en_US.UTF-8." "${LOCALE}"
        done

        if grep -q '^LC_ALL=' /etc/environment 2>/dev/null; then
            "$ESCALATION_TOOL" sed -i "s/^LC_ALL=.*/LC_ALL=${LOCALE}/" /etc/environment
        else
            printf 'LC_ALL=%s\n' "$LOCALE" | "$ESCALATION_TOOL" tee -a /etc/environment >/dev/null
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
