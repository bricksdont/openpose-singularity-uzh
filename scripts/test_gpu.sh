#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SIF_FILE="$REPO_DIR/openpose.sif"

if [ ! -f "$SIF_FILE" ]; then
    echo "ERROR: Container image not found: $SIF_FILE"
    echo "Run 'bash scripts/build_container.sh' first."
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

echo "=== GPU check (nvidia-smi inside container) ==="
$CONTAINER_CMD exec --nv "$SIF_FILE" nvidia-smi

echo
echo "=== OpenPose binary check (--help) ==="
$CONTAINER_CMD exec --nv "$SIF_FILE" /openpose/build/examples/openpose/openpose.bin --help 2>&1 | head -20

echo
echo "GPU verification passed."
