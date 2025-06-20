        apt-get|nala|dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade -y
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm --needed archlinux-keyring
            "$AUR_HELPER" -Su --noconfirm
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive dup
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" upgrade
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -yu
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
            exit 1
            ;;