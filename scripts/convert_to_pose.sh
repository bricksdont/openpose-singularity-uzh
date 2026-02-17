#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$REPO_DIR/venv"
KEYPOINTS_DIR="$REPO_DIR/data/output/keypoints"

if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Virtual environment not found: $VENV_DIR"
    echo "Run 'bash scripts/setup_venv.sh' first."
    exit 1
fi

if [ ! -d "$KEYPOINTS_DIR" ]; then
    echo "ERROR: Keypoints directory not found: $KEYPOINTS_DIR"
    echo "Run 'bash scripts/run_openpose.sh' first."
    exit 1
fi

JSON_COUNT=$(find "$KEYPOINTS_DIR" -name '*.json' 2>/dev/null | wc -l)
if [ "$JSON_COUNT" -eq 0 ]; then
    echo "ERROR: No JSON files found in $KEYPOINTS_DIR"
    exit 1
fi

echo "Found $JSON_COUNT keypoint JSON files."

source "$VENV_DIR/bin/activate"
python "$REPO_DIR/scripts/convert_to_pose.py" \
    --directory "$KEYPOINTS_DIR" \
    --output "$REPO_DIR/data/output/pose_output.pose"
