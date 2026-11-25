#!/bin/sh -e

. ./common.sh
gentoo_prepare

printf "%s" "Search Portage packages: "
if ! readMenuChoice search_term; then
    printf "\n"
    exit 1
fi

if [ -z "$search_term" ]; then
    printf "%b\n" "${YELLOW}No search term entered.${RC}"
    exit 1
fi

if command_exists eix; then
    eix "$search_term"
else
    emerge --search "$search_term"
fi
