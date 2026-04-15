#!/bin/sh -e

. ../../common-script.sh

installZathura() {
    if ! command_exists zathura; then
        PACKAGES="zathura"
        MSG=""

        if [ "$PACKAGER" = "pacman" ]; then # the MuPDF backend isn't in the apt repo yet
            PACKAGES="$PACKAGES zathura-pdf-mupdf"
            MSG="MuPDF backend installed. EPUB format is also supported."
        else
            PACKAGES="$PACKAGES zathura-pdf-poppler"
        fi

        printf "%b" "${GREEN}Install comic book (CBZ/CBR) support? [y/N] ${RC}"
        read -r cb_res
        if [ "$cb_res" = "y" ] || [ "$cb_res" = "Y" ]; then
            PACKAGES="$PACKAGES zathura-cb"
        fi

        printf "%b" "${GREEN}Install DjVu support? [y/N] ${RC}"
        read -r djvu_res
        if [ "$djvu_res" = "y" ] || [ "$djvu_res" = "Y" ]; then
            PACKAGES="$PACKAGES zathura-djvu"
        fi

        printf "%b\n" "${YELLOW}Installing Zathura and plugins...${RC}"
        case "$PACKAGER" in
            pacman)
                # shellcheck disable=SC2086
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm $PACKAGES
                ;;
            apk)
                # shellcheck disable=SC2086
                "$ESCALATION_TOOL" "$PACKAGER" add $PACKAGES
                ;;
            xbps-install)
                # shellcheck disable=SC2086
                "$ESCALATION_TOOL" "$PACKAGER" -Sy $PACKAGES
                ;;
            *)
                # shellcheck disable=SC2086
                "$ESCALATION_TOOL" "$PACKAGER" install -y $PACKAGES
                ;;
        esac

        if [ -n "$MSG" ]; then
            printf "%b\n" "${CYAN}$MSG${RC}"
        fi
    else
        printf "%b\n" "${GREEN}Zathura is already installed.${RC}"
    fi
}

setDefaultViewer() {
    if ! command_exists xdg-mime; then
        return 0
    fi

    printf "%b" "${GREEN}Set Zathura as default PDF viewer? [Y/n] ${RC}"
    read -r response
    if [ "$response" = "n" ] || [ "$response" = "N" ]; then
        printf "%b\n" "${YELLOW}Skipped setting Zathura as default PDF viewer.${RC}"
    else
        xdg-mime default org.pwmt.zathura.desktop application/pdf
        printf "%b\n" "${GREEN}Zathura set as default PDF viewer.${RC}"
    fi
}

checkEnv
checkEscalationTool
installZathura
setDefaultViewer
