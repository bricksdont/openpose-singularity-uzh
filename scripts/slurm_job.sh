#!/usr/bin/bash -l
#SBATCH --partition=lowprio
#SBATCH --gpus=V100:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=24:00:00

set -euo pipefail

# --- Arguments (passed by slurm_submit.sh) ---
CHUNK_DIR="$1"
OUTPUT_FOLDER="$2"
SCRIPT_DIR="$3"

echo "=== SLURM Job $SLURM_JOB_ID ==="
echo "Chunk dir: $CHUNK_DIR"
echo "Output folder: $OUTPUT_FOLDER"
echo "Node: $(hostname)"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'unknown')"
echo

module load apptainer

bash "$SCRIPT_DIR/batch_to_pose.sh" "$CHUNK_DIR" "$OUTPUT_FOLDER"

# Clean up chunk dir (contains only symlinks)
rm -rf "$CHUNK_DIR"
echo "Cleaned up chunk dir: $CHUNK_DIR"
