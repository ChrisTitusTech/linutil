#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which $1 >/dev/null 2>&1
}