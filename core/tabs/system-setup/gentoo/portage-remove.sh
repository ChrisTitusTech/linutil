#!/bin/sh -e

. ./common.sh
gentoo_prepare_privileged
gentoo_read_atom

printf "%b\n" "${YELLOW}This requests removal of the selected package. Portage will display the plan and ask for confirmation.${RC}"
"$ESCALATION_TOOL" emerge --ask --unmerge "$GENTOO_ATOM"
