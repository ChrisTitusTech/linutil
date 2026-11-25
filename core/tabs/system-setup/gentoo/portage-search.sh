#!/bin/sh -e

. ./common.sh
gentoo_prepare

printf "%s" "Search Portage packages: "
if ! readMenuChoice search_term; then
    printf "\n"
    exit 1
fi

case "$search_term" in
    ""|-*)
        printf "%b\n" "${YELLOW}Enter a non-empty search term that does not start with a dash.${RC}"
        exit 1
        ;;
esac

if command_exists eix; then
    eix "$search_term"
else
    emerge --search "$search_term"
fi
