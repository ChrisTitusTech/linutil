#!/bin/sh -e

. ../common-script.sh

checkEnv --no-aur

echo "LC_ALL=en_US.UTF-8" | "$ESCALATION_TOOL" tee -a /etc/environment
echo "en_US.UTF-8 UTF-8" | "$ESCALATION_TOOL" tee -a /etc/locale.gen
echo "LANG=en_US.UTF-8" | "$ESCALATION_TOOL" tee -a /etc/locale.conf
"$ESCALATION_TOOL" locale-gen en_US.UTF-8
