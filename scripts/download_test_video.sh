#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
INPUT_DIR="$REPO_DIR/data/input"
VIDEO_FILE="$INPUT_DIR/test_video.mp4"
VIDEO_URL="https://www.sgb-fss.ch/signsuisse/fileadmin/signsuisse_ressources/videos/262C81F5-FB9D-759D-08E1CB201ADEB239.mp4"

if [ -f "$VIDEO_FILE" ]; then
    echo "Test video already exists: $VIDEO_FILE"
    echo "Size: $(du -h "$VIDEO_FILE" | cut -f1)"
    echo "Skipping download. Delete the file to re-download."
    exit 0
fi

mkdir -p "$INPUT_DIR"

echo "Downloading test video..."
echo "URL: $VIDEO_URL"
wget -O "$VIDEO_FILE" "$VIDEO_URL"

echo
echo "Download complete: $VIDEO_FILE"
echo "Size: $(du -h "$VIDEO_FILE" | cut -f1)"
