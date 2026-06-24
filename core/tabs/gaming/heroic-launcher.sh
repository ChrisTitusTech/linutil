#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
LAUNCHER_PRESET=heroic sh "$SCRIPT_DIR/game-launchers.sh" heroic
