#!/bin/sh -e

. ../../common-script.sh

gentoo_prepare() {
    checkDistro
    if [ "$DTYPE" != "gentoo" ]; then
        printf "%b\n" "${RED}This utility is only available on Gentoo Linux.${RC}"
        exit 1
    fi
    if ! command_exists emerge; then
        printf "%b\n" "${RED}Portage (emerge) was not found.${RC}"
        exit 1
    fi
}

gentoo_prepare_privileged() {
    gentoo_prepare
    checkEscalationTool
}

gentoo_read_atom() {
    printf "%s" "Enter package atom (category/package): "
    if ! readMenuChoice GENTOO_ATOM; then
        printf "\n"
        exit 1
    fi

    case "$GENTOO_ATOM" in
        */*) ;;
        *)
            printf "%b\n" "${RED}Use a Portage atom in category/package form.${RC}"
            exit 1
            ;;
    esac

    case "$GENTOO_ATOM" in
        ""|-*|*[!A-Za-z0-9_+./:@-]*)
            printf "%b\n" "${RED}Invalid package atom. Only letters, numbers, and _ + . / : @ - are accepted.${RC}"
            exit 1
            ;;
    esac
}
