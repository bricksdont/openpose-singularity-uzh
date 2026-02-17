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

# 5. Set up Python virtual environment
bash scripts/setup_venv.sh

# 6. Convert keypoints to .pose format
bash scripts/convert_to_pose.sh

# 7. Visualize pose overlay on video
bash scripts/visualize_pose.sh
```

## Repository Structure

```
.
├── openpose.def                 # Singularity definition file (documentation/reproducibility)
├── requirements.txt             # Python dependencies for pose conversion/visualization
├── scripts/
│   ├── build_container.sh       # Pull the container image as openpose.sif
│   ├── test_gpu.sh              # Verify GPU and OpenPose binary inside container
│   ├── download_test_video.sh   # Download test video to data/input/
│   ├── run_openpose.sh          # Run OpenPose pose estimation
│   ├── setup_venv.sh            # Create Python venv and install dependencies
│   ├── convert_to_pose.py       # Convert OpenPose JSON to .pose format
│   ├── convert_to_pose.sh       # Run pose conversion
│   ├── visualize_pose.py        # Overlay .pose skeleton on video
│   └── visualize_pose.sh        # Run pose visualization
├── data/
│   ├── input/                   # Input videos (git-ignored)
│   └── output/                  # Results (git-ignored)
│       ├── output_video.avi     # Video with skeleton overlay
│       ├── keypoints/           # Per-frame JSON keypoint files
│       ├── pose_output.pose     # Binary .pose file
│       └── pose_overlay.mp4    # Video with .pose skeleton overlay
├── example/                     # Example pipeline output (committed to repo)
│   ├── input/test_video.mp4
│   └── output/
│       ├── output_video.avi
│       ├── keypoints/           # 133 JSON files
│       ├── pose_output.pose
│       └── pose_overlay.mp4
├── venv/                        # Python virtual environment (git-ignored)
└── openpose.sif                 # Container image (git-ignored)
```

## Output

After running the full pipeline, `data/output/` contains:

- **`output_video.avi`** — input video with skeleton overlay rendered on each frame
- **`keypoints/`** — one JSON file per frame with arrays:
  - `pose_keypoints_2d` (25 body keypoints, BODY_25 model)
  - `hand_left_keypoints_2d` (21 keypoints)
  - `hand_right_keypoints_2d` (21 keypoints)
  - `face_keypoints_2d` (70 keypoints)
- **`pose_output.pose`** — binary `.pose` file containing all keypoints in [pose-format](https://github.com/sign-language-processing/pose) structure
- **`pose_overlay.mp4`** — video with skeleton from `.pose` data overlaid on the original input

The `example/` directory contains a complete set of example outputs from the pipeline for reference.
