"""Fox negative rasmlarni yolo_dataset ga ko'chirish (bo'sh label = other)."""
import os
import random
import shutil
from pathlib import Path

import cv2

SOURCE_DIR = Path("negative_datasets/FoxDatasets/Fox")
OUT_DIR = Path("yolo_dataset")
PREFIX = "other_fox_"
SEED = 42
SPLIT = (0.8, 0.1, 0.1)
MAX_IMAGES = 500  # balans uchun limit
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".jfif", ".webp", ".bmp"}


def collect_images() -> list[Path]:
    images = []
    for path in SOURCE_DIR.rglob("*"):
        if path.is_file() and path.suffix.lower() in IMAGE_EXTS:
            images.append(path)
    return sorted(images)


def save_as_jpg(src: Path, dst: Path) -> bool:
    img = cv2.imread(str(src))
    if img is None:
        print(f"SKIP (o'qib bo'lmadi): {src}")
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(dst), img, [cv2.IMWRITE_JPEG_QUALITY, 95])
    return True


def main():
    random.seed(SEED)
    images = collect_images()
    if not images:
        print(f"Rasm topilmadi: {SOURCE_DIR}")
        return

    if len(images) > MAX_IMAGES:
        random.shuffle(images)
        images = sorted(images[:MAX_IMAGES])

    random.shuffle(images)
    n = len(images)
    n_train = int(n * SPLIT[0])
    n_valid = int(n * SPLIT[1])
    splits = {
        "train": images[:n_train],
        "valid": images[n_train : n_train + n_valid],
        "test": images[n_train + n_valid :],
    }

    counter = 1
    for split, files in splits.items():
        img_dir = OUT_DIR / split / "images"
        lbl_dir = OUT_DIR / split / "labels"
        img_dir.mkdir(parents=True, exist_ok=True)
        lbl_dir.mkdir(parents=True, exist_ok=True)

        ok = 0
        for src in files:
            name = f"{PREFIX}{counter:04d}.jpg"
            counter += 1
            dst_img = img_dir / name
            dst_lbl = lbl_dir / name.replace(".jpg", ".txt")

            if save_as_jpg(src, dst_img):
                dst_lbl.touch()  # bo'sh label
                ok += 1

        print(f"{split}: {ok}/{len(files)} ta fox qo'shildi")

    print(f"\nJami: {counter - 1} ta rasm yolo_dataset ga qo'shildi")


if __name__ == "__main__":
    main()
