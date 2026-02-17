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

echo "=== GPU check (nvidia-smi inside container) ==="
singularity exec --nv "$SIF_FILE" nvidia-smi

echo
echo "=== OpenPose binary check (--help) ==="
singularity exec --nv "$SIF_FILE" /openpose/build/examples/openpose/openpose.bin --help 2>&1 | head -20

echo
echo "GPU verification passed."
