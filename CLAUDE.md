# Project: OpenPose Singularity/Apptainer (UZH)

Run OpenPose pose estimation in a Singularity/Apptainer container with GPU acceleration, producing `.pose` files via the [pose-format](https://github.com/sign-language-processing/pose) library.

## Architecture

- **Container image:** `docker://cwaffles/openpose` pulled as `openpose.sif`. Uses OpenPose 1.5.1 with CUDA 10, compiled for GPU only (BODY_25, face, hand models). No CPU-only mode available.
- **Python venv:** Used for pose conversion (`pose-format` library) and visualization (`opencv-python`). Not inside the container.
- **Pipeline:** Video → OpenPose (in container, writes per-frame JSON keypoints) → `convert_to_pose.py` (in venv, converts to `.pose` binary format)

## Key scripts

- `scripts/batch_to_pose.sh` — Main batch pipeline: processes a folder of videos sequentially on one GPU
- `scripts/slurm_submit.sh` — Splits videos into N chunks, submits one SLURM GPU job per chunk
- `scripts/slurm_job.sh` — SLURM job script called by slurm_submit.sh (not run directly)
- `scripts/slurm_build_container.sh` — Builds the container as a SLURM job (login nodes lack memory for mksquashfs)

## UZH ScienceCluster specifics

- Container runtime is `apptainer`, loaded via `module load apptainer` (not in PATH by default)
- All scripts auto-detect apptainer vs singularity with `module load apptainer 2>/dev/null || true` before checking
- GPU request format: `--gpus=V100:1`
- Auto-bound paths: `/home`, `/scratch`, `/shares`, `/apps`
- Repo location on cluster: `/shares/sigma.ebling.cl.uzh/mathmu/openpose-singularity-uzh`
- SLURM copies job scripts to `/var/spool/slurmd/`, so `$(dirname "$0")` doesn't work inside SLURM jobs. Use `SLURM_SUBMIT_DIR` or pass paths as arguments instead.

## Performance benchmarks

| GPU | VRAM | Input Resolution | Speed |
|---|---|---|---|
| Tesla T4 | 15 GB | 640x480 | ~2.8 fps |
| Tesla V100 | 32 GB | 210x260 | ~4.1 fps |

GPU compute is near-saturated (86-93% on T4), so running multiple instances on the same GPU won't help. Scale by using multiple GPUs via SLURM.

## Known issues

- **pose-format fps bug:** The `pose-format` library truncates framerate to integer in several places (`utils/openpose.py:load_openpose()`, `tensorflow/pose_body.py` TFRecord serialization), despite `PoseBody.fps` being typed as float. This silently breaks non-integer framerates like 29.97 fps. Reported upstream.
- **CMU model server down:** `posefs1.perception.cs.cmu.edu` returns 404s, so COCO/MPI pose models can't be downloaded. Only BODY_25 model is available (bundled in `cwaffles/openpose`).
- **No CPU fallback:** The `cwaffles/openpose` image is GPU-only (linked to libcudart/libcublas/libcudnn). The `mvdoc/openpose-cpu` Docker image exists but only supports COCO/MPI models, not BODY_25, and the models can't be downloaded due to the server being down.
