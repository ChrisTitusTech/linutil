#!/bin/sh -e

. ./common.sh
gentoo_prepare

printf "%b\n" "${CYAN}Previewing a deep @world update. No packages will be installed or removed by this preview.${RC}"
emerge --pretend --verbose --update --deep --newuse @world
