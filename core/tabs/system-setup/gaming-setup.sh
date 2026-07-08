#!/bin/sh -e

# shellcheck disable=SC2086

. ../common-script.sh

INSTALL_FAILURES=""
INSTALL_CONFLICTS=""

strip_ansi() {
    esc=$(printf '\033')
    sed "s/${esc}\\[[0-9;?]*[ -/]*[@-~]//g"
}

extract_conflicts() {
    strip_ansi | sed -n '
        / are in conflict/ {
            s/^.*::[[:space:]]*//
            s/[[:space:]]*Remove .*$//
            s/\.$//
            s/[[:space:]]*$//
            p
        }
    '
}

record_step_failure() {
    step_name="$1"
    output_file="$2"
    conflicts=$(extract_conflicts < "$output_file" | sort -u)

    if [ -n "$conflicts" ]; then
        INSTALL_CONFLICTS="${INSTALL_CONFLICTS}\n${conflicts}"
    else
        INSTALL_FAILURES="${INSTALL_FAILURES}\n- ${step_name}"
    fi
}

run_install_step() {
    step_name="$1"
    shift
    step_output=$(mktemp)
    step_dir=$(mktemp -d)
    step_pipe="$step_dir/output.pipe"
    mkfifo "$step_pipe"

    printf "%b\n" "${CYAN}[RUNNING]${RC} ${step_name}"
    tee "$step_output" < "$step_pipe" &
    tee_pid=$!

    set +e
    "$@" > "$step_pipe" 2>&1
    step_status=$?
    wait "$tee_pid"
    set -e

    rm -rf "$step_dir"

    if [ "$step_status" -eq 0 ]; then
        printf "%b\n" "${GREEN}[OK]${RC} ${step_name}"
    else
        printf "%b\n" "${YELLOW}[FAILED]${RC} ${step_name}"
        record_step_failure "$step_name" "$step_output"
    fi

    rm -f "$step_output"
}

print_install_summary() {
    printf "\n"

    if [ -n "$INSTALL_CONFLICTS" ] || [ -n "$INSTALL_FAILURES" ]; then
        printf "%b\n" "${YELLOW}Partially completed. Please resolve failed steps, then re-run install:${RC}"
        if [ -n "$INSTALL_CONFLICTS" ]; then
            printf "%b\n" "${YELLOW}Conflicts:${RC}"
            printf "%b\n" "$INSTALL_CONFLICTS" | sed '/^$/d' | sort -u | sed 's/^/- /'
        fi
        if [ -n "$INSTALL_FAILURES" ]; then
            printf "%b\n" "${YELLOW}Failures:${RC}"
            printf "%b\n" "$INSTALL_FAILURES"
        fi
    else
        printf "%b\n" "${GREEN}Completed.${RC}"
    fi
}

installDepend() {
    DEPENDENCIES='wine dbus git'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            if grep -qi "Artix" /etc/os-release; then # Detect Artix Linux
                # Check for lib32
                if ! grep -q "^\s*\[lib32\]" /etc/pacman.conf; then
                    echo "[lib32]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    run_install_step "Refresh packages after enabling lib32" "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm
                else
                    printf "%b\n" "${GREEN}lib32 is already enabled.${RC}"
                fi
            else
                # Check for multilib
                if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                    echo "[multilib]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    run_install_step "Refresh packages after enabling multilib" "$ESCALATION_TOOL" "$PACKAGER" -Sy --noconfirm
                else
                    printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
                fi
            fi
            DISTRO_DEPS="gnutls lib32-gnutls base-devel gtk3 lib32-gtk3 python-google-auth python-protobuf \
                libpulse lib32-libpulse alsa-lib lib32-alsa-lib alsa-utils alsa-plugins lib32-alsa-plugins \
                giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap openal lib32-openal \
                libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama libgcrypt lib32-libgcrypt \
                libgpg-error lib32-libgpg-error ncurses lib32-ncurses mpg123 lib32-mpg123 \
                libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libva lib32-libva \
                gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils \
                vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd opencl-icd-loader lib32-opencl-icd-loader \
                libxslt lib32-libxslt cups samba lib32-mesa vulkan-radeon lib32-vulkan-radeon \
                gamescope mangohud lib32-mangohud gamemode lib32-gamemode"

            if "$PACKAGER" -Qq pipewire-jack >/dev/null 2>&1; then
                run_install_step "Install lib32-pipewire-jack" "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lib32-pipewire-jack
            elif "$PACKAGER" -Qq jack2 >/dev/null 2>&1; then
                run_install_step "Install lib32-jack2" "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm lib32-jack2
            fi

            run_install_step "Install main gaming dependencies (repo/AUR)" \
                "$AUR_HELPER" -S --needed --noconfirm dbus git $DISTRO_DEPS
            run_install_step "Install Wine" \
                "$AUR_HELPER" -S --needed --noconfirm wine
            ;;
        apt-get | nala)
            run_install_step "Enable i386 architecture" "$ESCALATION_TOOL" dpkg --add-architecture i386
            run_install_step "Refresh package indexes" "$ESCALATION_TOOL" "$PACKAGER" update
            
            run_install_step "Install base dependencies" "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES
            
            DISTRO_DEPS="libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386 wine32:i386"
            apt-cache show software-properties-common >/dev/null 2>&1 && DISTRO_DEPS="$DISTRO_DEPS software-properties-common"        
            run_install_step "Install distro-specific dependencies" "$ESCALATION_TOOL" "$PACKAGER" install -y $DISTRO_DEPS
            ;;
        dnf)
            printf "%b\n" "${CYAN}Installing rpmfusion repos.${RC}"
            run_install_step "Install RPM Fusion repositories" \
                "$ESCALATION_TOOL" "$PACKAGER" install \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" -y
            run_install_step "Enable fedora-cisco-openh264 repo" \
                "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt --repo fedora-cisco-openh264 enabled=1
    
            run_install_step "Install base dependencies" "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES
            ;;
        zypper)
            run_install_step "Install base dependencies" "$ESCALATION_TOOL" "$PACKAGER" -n install $DEPENDENCIES
            ;;
        eopkg)
            DISTRO_DEPS="libgnutls libgtk-2 libgtk-3 pulseaudio alsa-lib alsa-plugins giflib libpng openal-soft libxcomposite libxinerama ncurses vulkan ocl-icd libva gst-plugins-base sdl2 v4l-utils sqlite3"
            run_install_step "Install base and distro-specific dependencies" \
                "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES $DISTRO_DEPS
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

installAdditionalDepend() {
    case "$PACKAGER" in
        pacman)
            DISTRO_DEPS='goverlay'
            run_install_step "Install additional gaming utilities" \
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm $DISTRO_DEPS
            ;;
        apt-get | nala | dnf | zypper | eopkg)
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager ${PACKAGER}${RC}"
            exit 1
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend
installAdditionalDepend
print_install_summary
