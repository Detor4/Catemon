"""Kaggle Dog Segmentation -> YOLO format (class 1 = other)."""
import os
import random
import shutil

import cv2

SOURCE_IMAGES = "Dog Segmentation/Images"
SOURCE_LABELS = "Dog Segmentation/Labels"
OUT_DIR = "yolo_dataset"
CLASS_ID = 1
PREFIX = "other_"
SEED = 42
SPLIT = (0.8, 0.1, 0.1)  # train, valid, test


def mask_to_yolo_lines(mask, width, height):
    contours, _ = cv2.findContours(
        mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )
    lines = []
    for contour in contours:
        if len(contour) < 3 or cv2.contourArea(contour) < 100:
            continue
        points = contour.reshape(-1, 2)
        coords = []
        for x, y in points:
            coords.extend([x / width, y / height])
        line = f"{CLASS_ID} " + " ".join(f"{c:.6f}" for c in coords)
        lines.append(line)
    return lines


def convert_one(img_name, split):
    # dog.8788.jpg -> annotated_dog.8788.jpg
    core = img_name.replace("dog.", "")
    label_name = f"annotated_dog.{core}"

    img_path = f"{SOURCE_IMAGES}/{img_name}"
    lbl_path = f"{SOURCE_LABELS}/{label_name}"
    if not os.path.exists(lbl_path):
        print(f"SKIP: {label_name} topilmadi")
        return False

    image = cv2.imread(img_path)
    label = cv2.imread(lbl_path)
    if image is None or label is None:
        print(f"SKIP: o'qib bo'lmadi {img_name}")
        return False

    height, width = image.shape[:2]
    gray = cv2.cvtColor(label, cv2.COLOR_BGR2GRAY)
    _, mask = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)

    out_img = f"{OUT_DIR}/{split}/images/{PREFIX}{img_name}"
    out_lbl = f"{OUT_DIR}/{split}/labels/{PREFIX}{img_name.replace('.jpg', '.txt')}"

    shutil.copy(img_path, out_img)
    lines = mask_to_yolo_lines(mask, width, height)
    with open(out_lbl, "w") as f:
        f.write("\n".join(lines))
    return True


def main():
    random.seed(SEED)
    images = sorted(
        f for f in os.listdir(SOURCE_IMAGES) if f.lower().endswith(".jpg")
    )
    random.shuffle(images)

    n = len(images)
    n_train = int(n * SPLIT[0])
    n_valid = int(n * SPLIT[1])
    splits = {
        "train": images[:n_train],
        "valid": images[n_train : n_train + n_valid],
        "test": images[n_train + n_valid :],
    }

    for split in splits:
        os.makedirs(f"{OUT_DIR}/{split}/images", exist_ok=True)
        os.makedirs(f"{OUT_DIR}/{split}/labels", exist_ok=True)

    for split, files in splits.items():
        ok = sum(convert_one(name, split) for name in files)
        print(f"{split}: {ok}/{len(files)} ta other rasm qo'shildi")

    print("Tayyor!")


if __name__ == "__main__":
    main()
