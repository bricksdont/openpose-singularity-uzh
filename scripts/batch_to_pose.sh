#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SIF_FILE="$REPO_DIR/openpose.sif"
VENV_DIR="$REPO_DIR/venv"

# --- Usage ---
if [ $# -lt 2 ]; then
    echo "Usage: bash $0 <input_folder> <output_folder>"
    echo "Processes all video files (*.mp4, *.avi, *.mov) in input_folder"
    echo "and writes corresponding .pose files to output_folder."
    exit 1
fi

INPUT_FOLDER="$(realpath "$1")"
OUTPUT_FOLDER="$(realpath -m "$2")"

# --- Validation ---
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "ERROR: Input folder not found: $INPUT_FOLDER"
    exit 1
fi

# Collect video files
shopt -s nullglob
VIDEO_FILES=("$INPUT_FOLDER"/*.mp4 "$INPUT_FOLDER"/*.avi "$INPUT_FOLDER"/*.mov)
shopt -u nullglob

if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
    echo "ERROR: No video files (*.mp4, *.avi, *.mov) found in $INPUT_FOLDER"
    exit 1
fi

if [ ! -f "$SIF_FILE" ]; then
    echo "ERROR: Container image not found: $SIF_FILE"
    echo "Run 'bash scripts/build_container.sh' first."
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Virtual environment not found: $VENV_DIR"
    echo "Run 'bash scripts/setup_venv.sh' first."
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

mkdir -p "$OUTPUT_FOLDER"
source "$VENV_DIR/bin/activate"

# --- Helper functions ---
format_duration() {
    local secs=$1
    if [ "$secs" -ge 3600 ]; then
        printf "%dh%02dm%02ds" $((secs/3600)) $((secs%3600/60)) $((secs%60))
    elif [ "$secs" -ge 60 ]; then
        printf "%dm%02ds" $((secs/60)) $((secs%60))
    else
        printf "%ds" "$secs"
    fi
}

TOTAL=${#VIDEO_FILES[@]}
SUCCESS=0
FAILED=0
FAILED_FILES=()
TOTAL_FRAMES=0
BATCH_START=$(date +%s)

echo "Found $TOTAL video(s) in $INPUT_FOLDER"
echo "Output folder: $OUTPUT_FOLDER"
echo

for VIDEO_FILE in "${VIDEO_FILES[@]}"; do
    CURRENT=$((SUCCESS + FAILED + 1))
    BASENAME="$(basename "${VIDEO_FILE%.*}")"
    POSE_OUTPUT="$OUTPUT_FOLDER/${BASENAME}.pose"
    TEMP_KEYPOINTS="$(mktemp -d)"

    echo "--- [$CURRENT/$TOTAL] Processing: $(basename "$VIDEO_FILE") ---"

    VIDEO_START=$(date +%s)

    if $CONTAINER_CMD exec --nv \
        --bind "$INPUT_FOLDER:/input:ro" \
        --bind "$TEMP_KEYPOINTS:/output_keypoints" \
        "$SIF_FILE" \
        /openpose/build/examples/openpose/openpose.bin \
        --model_folder /openpose/models/ \
        --video "/input/$(basename "$VIDEO_FILE")" \
        --write_json /output_keypoints/ \
        --display 0 \
        --render_pose 0 \
        --model_pose BODY_25 \
        --face \
        --hand \
    && python "$SCRIPT_DIR/convert_to_pose.py" \
        --directory "$TEMP_KEYPOINTS" \
        --output "$POSE_OUTPUT" \
        --video "$VIDEO_FILE"; then
        SUCCESS=$((SUCCESS + 1))

        # Count frames from keypoint JSONs
        FRAME_COUNT=$(find "$TEMP_KEYPOINTS" -name '*.json' 2>/dev/null | wc -l)
        TOTAL_FRAMES=$((TOTAL_FRAMES + FRAME_COUNT))

        VIDEO_END=$(date +%s)
        VIDEO_ELAPSED=$((VIDEO_END - VIDEO_START))
        if [ "$VIDEO_ELAPSED" -gt 0 ]; then
            VIDEO_FPS=$(echo "scale=1; $FRAME_COUNT / $VIDEO_ELAPSED" | bc)
        else
            VIDEO_FPS="N/A"
        fi

        echo "  -> $POSE_OUTPUT ($FRAME_COUNT frames, ${VIDEO_FPS} fps)"
    else
        FAILED=$((FAILED + 1))
        FAILED_FILES+=("$(basename "$VIDEO_FILE")")
        echo "  -> FAILED"
    fi

    rm -rf "$TEMP_KEYPOINTS"

    # Progress estimate
    DONE=$((SUCCESS + FAILED))
    REMAINING=$((TOTAL - DONE))
    NOW=$(date +%s)
    ELAPSED=$((NOW - BATCH_START))
    if [ "$DONE" -gt 0 ] && [ "$REMAINING" -gt 0 ]; then
        AVG_PER_VIDEO=$((ELAPSED / DONE))
        ETA=$((AVG_PER_VIDEO * REMAINING))
        echo "  Progress: $DONE/$TOTAL | Elapsed: $(format_duration $ELAPSED) | ETA: ~$(format_duration $ETA)"
    fi

    if [ "$ELAPSED" -gt 0 ] && [ "$TOTAL_FRAMES" -gt 0 ]; then
        OVERALL_FPS=$(echo "scale=1; $TOTAL_FRAMES / $ELAPSED" | bc)
        echo "  Overall speed: ${OVERALL_FPS} fps ($TOTAL_FRAMES frames in $(format_duration $ELAPSED))"
    fi
    echo
done

BATCH_END=$(date +%s)
BATCH_ELAPSED=$((BATCH_END - BATCH_START))
if [ "$BATCH_ELAPSED" -gt 0 ] && [ "$TOTAL_FRAMES" -gt 0 ]; then
    FINAL_FPS=$(echo "scale=1; $TOTAL_FRAMES / $BATCH_ELAPSED" | bc)
else
    FINAL_FPS="N/A"
fi

echo "=== Summary ==="
echo "Total: $TOTAL | Succeeded: $SUCCESS | Failed: $FAILED"
echo "Total frames: $TOTAL_FRAMES | Time: $(format_duration $BATCH_ELAPSED) | Avg speed: ${FINAL_FPS} fps"
if [ $FAILED -gt 0 ]; then
    echo "Failed files:"
    for f in "${FAILED_FILES[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
