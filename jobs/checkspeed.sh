#!/usr/bin/env bash

# Check for official speedtest CLI
if ! command -v speedtest &> /dev/null; then
    echo "Official speedtest CLI not found. Attempting to install via snap..."
    sudo snap install speedtest
    if ! command -v speedtest &> /dev/null; then
        echo "Installation failed. Please install the official speedtest CLI manually."
        exit 1
    fi
fi

echo "Running official speed test at $(date '+%Y-%m-%d %H:%M:%S')…"

# Run and display results
speedtest --json

echo "Speed test completed."

