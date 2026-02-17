#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$REPO_DIR/venv"
POSE_FILE="$REPO_DIR/data/output/pose_output.pose"
VIDEO_FILE="$REPO_DIR/data/input/test_video.mp4"

if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Virtual environment not found: $VENV_DIR"
    echo "Run 'bash scripts/setup_venv.sh' first."
    exit 1
fi

if [ ! -f "$POSE_FILE" ]; then
    echo "ERROR: Pose file not found: $POSE_FILE"
    echo "Run 'bash scripts/convert_to_pose.sh' first."
    exit 1
fi

if [ ! -f "$VIDEO_FILE" ]; then
    echo "ERROR: Video file not found: $VIDEO_FILE"
    echo "Run 'bash scripts/download_test_video.sh' first."
    exit 1
fi

source "$VENV_DIR/bin/activate"
python "$REPO_DIR/scripts/visualize_pose.py" \
    --pose "$POSE_FILE" \
    --video "$VIDEO_FILE" \
    --output "$REPO_DIR/data/output/pose_overlay.mp4"
