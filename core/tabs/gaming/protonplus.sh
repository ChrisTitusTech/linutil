#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
PROTON_TOOL_PRESET=protonplus sh "$SCRIPT_DIR/proton-tools.sh" protonplus
