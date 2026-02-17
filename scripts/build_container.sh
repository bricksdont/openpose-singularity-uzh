#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SIF_FILE="$REPO_DIR/openpose.sif"
DOCKER_IMAGE="docker://cwaffles/openpose"

if [ -f "$SIF_FILE" ]; then
    echo "Container image already exists: $SIF_FILE"
    echo "Size: $(du -h "$SIF_FILE" | cut -f1)"
    echo "Skipping build. Delete the file to rebuild."
    exit 0
fi

# --- Detect container runtime ---
if command -v apptainer &>/dev/null; then
    CONTAINER_CMD=apptainer
elif command -v singularity &>/dev/null; then
    CONTAINER_CMD=singularity
else
    echo "ERROR: Neither apptainer nor singularity found in PATH."
    exit 1
fi

echo "Pulling OpenPose container image..."
echo "Source: $DOCKER_IMAGE"
echo "This may take 10-15 minutes depending on network speed."
echo

$CONTAINER_CMD pull "$SIF_FILE" "$DOCKER_IMAGE"

echo
echo "Build complete: $SIF_FILE"
echo "Size: $(du -h "$SIF_FILE" | cut -f1)"
