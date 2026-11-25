#!/bin/sh -e

. ./common.sh
gentoo_prepare_privileged
gentoo_read_atom

printf "%b\n" "${YELLOW}Portage will show the proposed package changes and ask for confirmation.${RC}"
"$ESCALATION_TOOL" emerge --ask --verbose "$GENTOO_ATOM"
