#!/bin/bash

# Script to generate preview.gif locally using VHS
# Requirements: vhs, ffmpeg, ttyd, and JetBrains Mono font

set -e

# Check if VHS is installed
if ! command -v vhs &> /dev/null; then
    echo "Error: VHS is not installed"
    echo "Install it with: go install github.com/charmbracelet/vhs@latest"
    exit 1
fi

# Check if linutil binary exists
if ! command -v linutil &> /dev/null && [ ! -f "./build/linutil" ] && [ ! -f "./target/release/linutil" ]; then
    echo "Error: linutil binary not found"
    echo "Build it first with: cargo build --release"
    exit 1
fi

# Add linutil to PATH if needed
if [ -f "./target/release/linutil" ]; then
    export PATH="$PWD/target/release:$PATH"
elif [ -f "./build/linutil" ]; then
    export PATH="$PWD/build:$PATH"
fi

echo "Generating preview.gif..."
cd .github
vhs preview.tape

echo "✓ Preview generated successfully at .github/preview.gif"
