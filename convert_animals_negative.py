"""Animals negative rasmlarni yolo_dataset ga ko'chirish (gatto/mushuk tashlab yuboriladi)."""
import random
from pathlib import Path

import cv2

SOURCE_DIR = Path("negative_datasets/Animals/raw-img")
OUT_DIR = Path("yolo_dataset")
PREFIX = "other_animal_"
EXCLUDE_DIRS = {"gatto"}
SEED = 42
SPLIT = (0.8, 0.1, 0.1)
MAX_PER_CLASS = 80  # har bir hayvon turidan max
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".jfif", ".webp", ".bmp"}


def collect_by_class() -> dict[str, list[Path]]:
    groups: dict[str, list[Path]] = {}
    for class_dir in sorted(SOURCE_DIR.iterdir()):
        if not class_dir.is_dir() or class_dir.name in EXCLUDE_DIRS:
            continue
        images = [
            p
            for p in class_dir.rglob("*")
            if p.is_file() and p.suffix.lower() in IMAGE_EXTS
        ]
        if images:
            groups[class_dir.name] = images
    return groups


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
    groups = collect_by_class()
    if not groups:
        print(f"Rasm topilmadi: {SOURCE_DIR}")
        return

    selected: list[Path] = []
    print("Klasslar (gatto tashlab yuborildi):")
    for name, images in groups.items():
        random.shuffle(images)
        take = images[: min(MAX_PER_CLASS, len(images))]
        selected.extend(take)
        print(f"  {name}: {len(take)}/{len(images)}")

    random.shuffle(selected)
    n = len(selected)
    n_train = int(n * SPLIT[0])
    n_valid = int(n * SPLIT[1])
    splits = {
        "train": selected[:n_train],
        "valid": selected[n_train : n_train + n_valid],
        "test": selected[n_train + n_valid :],
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
                dst_lbl.touch()
                ok += 1

        print(f"{split}: {ok}/{len(files)} ta animal qo'shildi")

    print(f"\nJami: {counter - 1} ta rasm yolo_dataset ga qo'shildi")


if __name__ == "__main__":
    main()
