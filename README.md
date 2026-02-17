# OpenPose Singularity (UZH)

Run [OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose) pose estimation inside a Singularity container with GPU acceleration.

## Prerequisites

- Singularity CE >= 3.7
- NVIDIA GPU with driver supporting CUDA 11.x (tested with Tesla T4, driver 590.48.01)
- `wget` (for downloading test video)

## Quick Start

```bash
# 1. Build (pull) the Singularity container image (~10-15 min)
bash scripts/build_container.sh

# 2. Verify GPU access inside the container
bash scripts/test_gpu.sh

# 3. Download a test video
bash scripts/download_test_video.sh

# 4. Run OpenPose on the test video
bash scripts/run_openpose.sh
```

## Repository Structure

```
.
├── openpose.def                 # Singularity definition file (documentation/reproducibility)
├── scripts/
│   ├── build_container.sh       # Pull the container image as openpose.sif
│   ├── test_gpu.sh              # Verify GPU and OpenPose binary inside container
│   ├── download_test_video.sh   # Download test video to data/input/
│   └── run_openpose.sh          # Run OpenPose pose estimation
├── data/
│   ├── input/                   # Input videos (git-ignored)
│   └── output/                  # Results (git-ignored)
│       ├── output_video.avi     # Video with skeleton overlay
│       └── keypoints/           # Per-frame JSON keypoint files
└── openpose.sif                 # Container image (git-ignored)
```

## Output

After running OpenPose, `data/output/` contains:

- **`output_video.avi`** — input video with skeleton overlay rendered on each frame
- **`keypoints/`** — one JSON file per frame with arrays:
  - `pose_keypoints_2d` (25 body keypoints, BODY_25 model)
  - `hand_left_keypoints_2d` (21 keypoints)
  - `hand_right_keypoints_2d` (21 keypoints)
  - `face_keypoints_2d` (70 keypoints)
