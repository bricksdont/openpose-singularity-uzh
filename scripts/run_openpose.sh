#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SIF_FILE="$REPO_DIR/openpose.sif"
INPUT_DIR="$REPO_DIR/data/input"
OUTPUT_DIR="$REPO_DIR/data/output"
KEYPOINTS_DIR="$OUTPUT_DIR/keypoints"

VIDEO_FILE="${1:-$INPUT_DIR/test_video.mp4}"

if [ ! -f "$SIF_FILE" ]; then
    echo "ERROR: Container image not found: $SIF_FILE"
    echo "Run 'bash scripts/build_container.sh' first."
    exit 1
fi

if [ ! -f "$VIDEO_FILE" ]; then
    echo "ERROR: Video file not found: $VIDEO_FILE"
    echo "Run 'bash scripts/download_test_video.sh' or provide a path as argument."
    exit 1
fi

# --- Detect container runtime ---
module load apptainer 2>/dev/null || true
if command -v apptainer &>/dev/null; then
    CONTAINER_CMD=apptainer
elif command -v singularity &>/dev/null; then
    CONTAINER_CMD=singularity
else
    echo "ERROR: Neither apptainer nor singularity found in PATH."
    exit 1
fi

mkdir -p "$KEYPOINTS_DIR"

echo "Running OpenPose pose estimation..."
echo "Input video: $VIDEO_FILE"
echo "Output directory: $OUTPUT_DIR"
echo

$CONTAINER_CMD exec --nv \
    --bind "$INPUT_DIR:/input:ro" \
    --bind "$OUTPUT_DIR:/output" \
    "$SIF_FILE" \
    /openpose/build/examples/openpose/openpose.bin \
    --model_folder /openpose/models/ \
    --video "/input/$(basename "$VIDEO_FILE")" \
    --write_json /output/keypoints/ \
    --write_video /output/output_video.avi \
    --display 0 \
    --render_pose 1 \
    --model_pose BODY_25 \
    --face \
    --hand

echo
echo "=== Summary ==="
if [ -f "$OUTPUT_DIR/output_video.avi" ]; then
    echo "Output video: $OUTPUT_DIR/output_video.avi ($(du -h "$OUTPUT_DIR/output_video.avi" | cut -f1))"
else
    echo "WARNING: Output video not found."
fi

JSON_COUNT=$(find "$KEYPOINTS_DIR" -name '*.json' 2>/dev/null | wc -l)
echo "Keypoint JSON files: $JSON_COUNT"
