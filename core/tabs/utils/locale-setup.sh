#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

get_suggested_locale() {
    key="$1"
    default_locale="en_US.UTF-8"

    # Use case statement to map keys to values (POSIX standard)
    case "$key" in
        us) echo "en_US.UTF-8" ;;
        uk) echo "en_GB.UTF-8" ;;
        ca) echo "en_CA.UTF-8" ;;
        cf) echo "fr_CA.UTF-8" ;;
        cn) echo "zh_CN.UTF-8" ;;
        by) echo "be_BY.UTF-8" ;;
        cz) echo "cs_CZ.UTF-8" ;;
        de) echo "de_DE.UTF-8" ;;
        dk) echo "da_DK.UTF-8" ;;
        es) echo "es_ES.UTF-8" ;;
        et) echo "et_EE.UTF-8" ;;
        fa) echo "fa_IR.UTF-8" ;;
        fi) echo "fi_FI.UTF-8" ;;
        fr) echo "fr_FR.UTF-8" ;;
        gr) echo "el_GR.UTF-8" ;;
        hu) echo "hu_HU.UTF-8" ;;
        il) echo "he_IL.UTF-8" ;;
        it) echo "it_IT.UTF-8" ;;
        jp) echo "ja_JP.UTF-8" ;;
        kr) echo "ko_KR.UTF-8" ;;
        lt) echo "lt_LT.UTF-8" ;;
        lv) echo "lv_LV.UTF-8" ;;
        mk) echo "mk_MK.UTF-8" ;;
        nl) echo "nl_NL.UTF-8" ;;
        no) echo "nb_NO.UTF-8" ;;
        ph) echo "en_PH.UTF-8" ;;
        pl) echo "pl_PL.UTF-8" ;;
        ro) echo "ro_RO.UTF-8" ;;
        ru) echo "ru_RU.UTF-8" ;;
        se) echo "sv_SE.UTF-8" ;;
        sg) echo "de_CH.UTF-8" ;;
        si) echo "sl_SI.UTF-8" ;;
        tr) echo "tr_TR.UTF-8" ;;
        ua) echo "uk_UA.UTF-8" ;;
        *) echo "$default_locale" ;; # Default fallback
    esac
}

setLocale() {
    if command_exists locale-gen; then

        iso=$(curl ifconfig.io/country_code | tr '[:upper:]' '[:lower:]')
        suggested_locale=$(get_suggested_locale "$iso")

        while true; do
            printf "Detected locale: '%s'. Press Enter to accept or type a new one (e.g. de_DE.UTF-8): " "$suggested_locale"
            read -r input
            LOCALE="${input:-$suggested_locale}"

            case "$LOCALE" in
                *_**)
                    # Check 2: Must end with .UTF-8
                    if echo "$LOCALE" | grep -qE '\.UTF-8$'; then
                        # Found a likely valid locale format
                        break
                    fi
                    ;;
            esac

            # If we reach here, the validation failed
            echo "ERROR! Locale '$LOCALE' does not look valid. Please enter a locale like en_US.UTF-8."
        done

        echo "LC_ALL=${LOCALE}" | "$ESCALATION_TOOL" tee -a /etc/environment
        echo "$LOCALE UTF-8" | "$ESCALATION_TOOL" tee -a /etc/locale.gen
        echo "LANG=$LOCALE" | "$ESCALATION_TOOL" tee -a /etc/locale.conf
        "$ESCALATION_TOOL" locale-gen "$LOCALE"
    fi
}

checkEnv
setLocale
