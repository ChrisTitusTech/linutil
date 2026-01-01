#!/usr/bin/env bash
set -e

# Path to your AppImage
APPIMAGE="$HOME/Downloads/Video2X-x86_64.AppImage"

# Source and output directories
SRC_DIR="$HOME/Videos/Hidamari"
OUT_DIR="$HOME/Videos/Hidamari/upscaled"

# Create output folder
mkdir -p "$OUT_DIR"

# Models and settings (adjustable)
MODEL="realesr-animevideov3"   # good for anime-style videos
SCALE="2"                     # 2× upscaling

echo "Upscaling all videos in $SRC_DIR → $OUT_DIR"

for f in "$SRC_DIR"/*.{mp4,mkv,avi,webm}; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    name="${base%.*}"
    echo "Processing: $base"

    "$APPIMAGE" \
      -i "$f" \
      -o "$OUT_DIR/${name}_upscaled.mp4" \
      -p realesrgan \
      -s "$SCALE" \
      --realesrgan-model "$MODEL"

    echo "Done: $name"
done

echo "All done."
