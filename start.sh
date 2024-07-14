#!/bin/sh

RC='\033[0m'
RED='\033[0;31m'

linutil="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"

check() {
    local exit_code=$1
    local message=$2

    if [ $exit_code -ne 0 ]; then
        echo "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

TMPFILE=$(mktemp)
check $? "Creating the temporary file"

curl -fsL $linutil -o $TMPFILE
check $? "Downloading linutil"

chmod +x $TMPFILE
check $? "Making linutil executable"

"$TMPFILE"
check $? "Executing linutil"

rm -f $TMPFILE
check $? "Deleting the temporary file"
