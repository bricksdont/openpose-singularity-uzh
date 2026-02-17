#!/usr/bin/env python3
"""Overlay pose skeleton on the original video using a .pose file."""

import argparse
import os

import cv2
from pose_format import Pose
from pose_format.pose_visualizer import PoseVisualizer


def main():
    parser = argparse.ArgumentParser(description="Visualize .pose data overlaid on video")
    parser.add_argument("--pose", default="data/output/pose_output.pose",
                        help="Input .pose file (default: data/output/pose_output.pose)")
    parser.add_argument("--video", default="data/input/test_video.mp4",
                        help="Input video file (default: data/input/test_video.mp4)")
    parser.add_argument("--output", default="data/output/pose_overlay.mp4",
                        help="Output video file (default: data/output/pose_overlay.mp4)")
    args = parser.parse_args()

    if not os.path.isfile(args.pose):
        print(f"ERROR: Pose file not found: {args.pose}")
        raise SystemExit(1)

    if not os.path.isfile(args.video):
        print(f"ERROR: Video file not found: {args.video}")
        raise SystemExit(1)

    print(f"Loading pose data from {args.pose} ...")
    with open(args.pose, "rb") as f:
        pose = Pose.read(f.read())

    # The pose-format library truncates FPS to int, but the visualizer
    # requires an exact match with the video FPS. Patch to match the video.
    cap = cv2.VideoCapture(args.video)
    video_fps = cap.get(cv2.CAP_PROP_FPS)
    cap.release()
    pose.body.fps = video_fps

    print(f"Overlaying skeleton on {args.video} (fps={video_fps:.2f}) ...")
    v = PoseVisualizer(pose)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    v.save_video(args.output, v.draw_on_video(args.video))

    file_size = os.path.getsize(args.output)
    print()
    print("=== Summary ===")
    print(f"Output: {args.output} ({file_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    main()
