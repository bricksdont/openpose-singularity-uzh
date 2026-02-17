#!/usr/bin/env python3
"""Convert OpenPose JSON keypoints to a binary .pose file."""

import argparse
import os

from pose_format.utils.openpose import load_openpose_directory


def main():
    parser = argparse.ArgumentParser(description="Convert OpenPose JSON keypoints to .pose format")
    parser.add_argument("--directory", default="data/output/keypoints/",
                        help="Directory containing OpenPose JSON files (default: data/output/keypoints/)")
    parser.add_argument("--output", default="data/output/pose_output.pose",
                        help="Output .pose file path (default: data/output/pose_output.pose)")
    parser.add_argument("--fps", type=float, default=24, help="Video frame rate (default: 24)")
    parser.add_argument("--width", type=int, default=640, help="Video width in pixels (default: 640)")
    parser.add_argument("--height", type=int, default=480, help="Video height in pixels (default: 480)")
    parser.add_argument("--video", default=None,
                        help="Path to source video file; when provided, fps/width/height are read from the video")
    args = parser.parse_args()

    if args.video is not None:
        import cv2
        cap = cv2.VideoCapture(args.video)
        if not cap.isOpened():
            print(f"ERROR: Cannot open video file: {args.video}")
            raise SystemExit(1)
        args.fps = cap.get(cv2.CAP_PROP_FPS)
        args.width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        args.height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        cap.release()

    if not os.path.isdir(args.directory):
        print(f"ERROR: Keypoints directory not found: {args.directory}")
        raise SystemExit(1)

    json_files = [f for f in os.listdir(args.directory) if f.endswith(".json")]
    if not json_files:
        print(f"ERROR: No JSON files found in {args.directory}")
        raise SystemExit(1)

    print(f"Loading OpenPose keypoints from {args.directory} ...")
    print(f"Video properties: {args.width}x{args.height} @ {args.fps} fps")

    pose = load_openpose_directory(args.directory, fps=args.fps, width=args.width, height=args.height)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "wb") as f:
        pose.write(f)

    file_size = os.path.getsize(args.output)
    num_frames = len(json_files)
    print()
    print("=== Summary ===")
    print(f"Frames: {num_frames}")
    print(f"Output: {args.output} ({file_size / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
