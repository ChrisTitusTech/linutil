#!/bin/sh -e

. ./common-script.sh

command_exists ls pwd
[ $? -eq 0 ] || echo "FAIL: existing commands test"

command_exists nonexistentcmd1 
[ $? -eq 1 ] || echo "FAIL: non-existing command test"

command_exists ls nonexistentcmd2 pwd
[ $? -eq 1 ] || echo "FAIL: mixed commands test"

command_exists nonexistentcmd3 nonexistentcmd4
[ $? -eq 1 ] || echo "FAIL: multiple non-existing test"

echo "All tests completed"
