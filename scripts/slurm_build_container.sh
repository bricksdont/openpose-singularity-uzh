#!/usr/bin/bash -l
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --job-name=openpose_build
#SBATCH --output=slurm_build_%j.out

set -euo pipefail

# SLURM copies job scripts to a temp directory, so $(dirname "$0") won't
# point to the original location. Use SLURM_SUBMIT_DIR instead.
SCRIPT_DIR="$SLURM_SUBMIT_DIR/scripts"

echo "=== Building OpenPose container ==="
echo "Node: $(hostname)"
echo

bash "$SCRIPT_DIR/build_container.sh"
