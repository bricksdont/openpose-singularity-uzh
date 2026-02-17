#!/usr/bin/bash -l
#SBATCH --partition=lowprio
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --job-name=openpose_build
#SBATCH --output=slurm_build_%j.out

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building OpenPose container ==="
echo "Node: $(hostname)"
echo

bash "$SCRIPT_DIR/build_container.sh"
