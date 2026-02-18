#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SIF_FILE="$REPO_DIR/openpose.sif"
VENV_DIR="$REPO_DIR/venv"

# --- Usage ---
usage() {
    echo "Usage: bash $0 <input_folder> <output_folder> [--chunks N]"
    echo
    echo "Submit parallel SLURM jobs to process videos into .pose files."
    echo "Splits input videos into N chunks and submits one GPU job per chunk."
    echo
    echo "Options:"
    echo "  --chunks N   Number of parallel jobs (default: 4)"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

INPUT_FOLDER="$(realpath "$1")"
OUTPUT_FOLDER="$(realpath -m "$2")"
shift 2

NUM_CHUNKS=4
while [ $# -gt 0 ]; do
    case "$1" in
        --chunks)
            NUM_CHUNKS="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            usage
            ;;
    esac
done

# --- Validation ---
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "ERROR: Input folder not found: $INPUT_FOLDER"
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

if ! command -v sbatch &>/dev/null; then
    echo "ERROR: sbatch not found. This script must be run on a SLURM cluster."
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

TOTAL=${#VIDEO_FILES[@]}

# Cap chunks to number of videos
if [ "$NUM_CHUNKS" -gt "$TOTAL" ]; then
    NUM_CHUNKS=$TOTAL
fi

echo "Found $TOTAL video(s) in $INPUT_FOLDER"
echo "Splitting into $NUM_CHUNKS chunk(s)"
echo

# --- Create staging directories ---
STAGING_DIR="$OUTPUT_FOLDER/.slurm_chunks"
LOG_DIR="$OUTPUT_FOLDER/.slurm_logs"
mkdir -p "$LOG_DIR"

# Clean up any previous staging
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

for i in $(seq 0 $((NUM_CHUNKS - 1))); do
    mkdir -p "$STAGING_DIR/chunk_$i"
done

# --- Distribute videos via symlinks (round-robin) ---
IDX=0
for VIDEO_FILE in "${VIDEO_FILES[@]}"; do
    CHUNK=$((IDX % NUM_CHUNKS))
    ln -s "$VIDEO_FILE" "$STAGING_DIR/chunk_$CHUNK/$(basename "$VIDEO_FILE")"
    IDX=$((IDX + 1))
done

# Report distribution
for i in $(seq 0 $((NUM_CHUNKS - 1))); do
    COUNT=$(find "$STAGING_DIR/chunk_$i" -type l | wc -l)
    echo "  Chunk $i: $COUNT video(s)"
done
echo

# --- Submit SLURM jobs ---
JOB_IDS=()
for i in $(seq 0 $((NUM_CHUNKS - 1))); do
    CHUNK_DIR="$STAGING_DIR/chunk_$i"
    JOB_ID=$(sbatch \
        --job-name="openpose_chunk_$i" \
        --output="$LOG_DIR/job_%j.out" \
        "$SCRIPT_DIR/slurm_job.sh" "$CHUNK_DIR" "$OUTPUT_FOLDER" "$SCRIPT_DIR" \
        | grep -o '[0-9]*')
    JOB_IDS+=("$JOB_ID")
    echo "Submitted chunk $i -> SLURM job $JOB_ID"
done

echo
echo "=== Summary ==="
echo "Jobs submitted: ${#JOB_IDS[@]}"
echo "Job IDs: ${JOB_IDS[*]}"
echo "Log directory: $LOG_DIR"
echo
echo "Monitor with:  squeue -u \$USER"
echo "View logs:     tail -f $LOG_DIR/job_*.out"
