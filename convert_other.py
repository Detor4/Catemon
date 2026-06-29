"""Dog (yoki boshqa) segmentation datasetni YOLO formatiga o'tkazish — class 1 = other."""
import json
import os
import shutil

import cv2
import numpy as np
from pycocotools import mask as maskUtils

SOURCE_DIR = "dog-segmentation-dataset/original"
OUT_DIR = "yolo_dataset"
CLASS_ID = 1  # 0=cat, 1=other
PREFIX = "other_"


def convert_split(split: str) -> None:
    img_dir = f"{SOURCE_DIR}/{split}"
    out_img_dir = f"{OUT_DIR}/{split}/images"
    out_label_dir = f"{OUT_DIR}/{split}/labels"

    if not os.path.isdir(img_dir):
        print(f"SKIP {split}: {img_dir} topilmadi")
        return

    os.makedirs(out_img_dir, exist_ok=True)
    os.makedirs(out_label_dir, exist_ok=True)

    count = 0
    for fname in os.listdir(img_dir):
        if not fname.endswith(".json"):
            continue

        with open(f"{img_dir}/{fname}") as f:
            data = json.load(f)

        img_info = data["image"]
        width, height = img_info["width"], img_info["height"]
        img_name = f"{PREFIX}{img_info['file_name']}"
        label_name = f"{PREFIX}{fname.replace('.json', '.txt')}"

        src = f"{img_dir}/{img_info['file_name']}"
        dst = f"{out_img_dir}/{img_name}"
        if os.path.exists(src):
            shutil.copy(src, dst)

        lines = []
        for ann in data["annotations"]:
            seg = ann["segmentation"]
            rle = {
                "counts": seg["counts"].encode("ascii"),
                "size": seg["size"],
            }
            binary_mask = maskUtils.decode(rle)
            if binary_mask.ndim == 3:
                binary_mask = binary_mask[:, :, 0]

            contours, _ = cv2.findContours(
                binary_mask.astype(np.uint8),
                cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE,
            )
            if not contours:
                continue

            contour = max(contours, key=cv2.contourArea)
            if len(contour) < 3:
                continue

            points = contour.reshape(-1, 2)
            coords = []
            for x, y in points:
                coords.extend([x / width, y / height])

            line = f"{CLASS_ID} " + " ".join(f"{c:.6f}" for c in coords)
            lines.append(line)

        with open(f"{out_label_dir}/{label_name}", "w") as f:
            f.write("\n".join(lines))
        count += 1

    print(f"{split}: {count} ta other rasm qo'shildi")


if __name__ == "__main__":
    for split in ("train", "valid", "test"):
        convert_split(split)
    print("Other klass konvertatsiyasi tayyor!")
