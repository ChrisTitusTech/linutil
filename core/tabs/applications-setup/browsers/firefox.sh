#!/bin/sh -e

. ../../common-script.sh

setupMozillaRepo() {
    "$ESCALATION_TOOL" install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /tmp/mozilla-key.gpg
    KEY_FILE=packages.mozilla.org.gpg
    if ! "$ESCALATION_TOOL" gpg --batch --yes --dearmor -o /etc/apt/keyrings/$KEY_FILE /tmp/mozilla-key.gpg 2>/dev/null; then
        "$ESCALATION_TOOL" cp /tmp/mozilla-key.gpg /etc/apt/keyrings/packages.mozilla.org.asc
        KEY_FILE=packages.mozilla.org.asc
    fi
    rm -f /tmp/mozilla-key.gpg

    "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/mozilla.sources > /dev/null << EOF
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/$KEY_FILE
EOF

    "$ESCALATION_TOOL" tee /etc/apt/preferences.d/mozilla > /dev/null << 'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
}

installFirefox() {
    if [ "$DTYPE" = "ubuntu" ] && command_exists snap && snap list firefox 2>/dev/null | grep -q firefox; then
        printf "%b\n" "${YELLOW}Removing Snap Firefox...${RC}"
        "$ESCALATION_TOOL" snap remove firefox
    fi
    if ! command_exists firefox; then
        printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                if [ "$DTYPE" = "ubuntu" ]; then
                    setupMozillaRepo
                    "$ESCALATION_TOOL" "$PACKAGER" update
                    "$ESCALATION_TOOL" "$PACKAGER" install -y firefox
                else
                    "$ESCALATION_TOOL" "$PACKAGER" install -y firefox-esr
                fi
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install MozillaFirefox
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm firefox
                ;;
            dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" -y install firefox
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy firefox
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add firefox
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive org.mozilla.firefox
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Firefox Browser is already installed.${RC}"
    fi
}

checkEnv
installFirefox
