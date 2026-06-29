import json, os, cv2, shutil
from pycocotools import mask as maskUtils
import numpy as np

def convert_to_yolo(split):
    img_dir = f"feral-cat-segmentation-dataset/original/{split}"
    out_dir = f"yolo_dataset/{split}"

    os.makedirs(f"{out_dir}/images", exist_ok=True)
    os.makedirs(f"{out_dir}/labels", exist_ok=True)

    for fname in os.listdir(img_dir):
        if not fname.endswith(".json"):
            continue

        with open(f"{img_dir}/{fname}") as f:
            data = json.load(f)

        img_info = data["image"]
        W, H = img_info["width"], img_info["height"]
        img_name = img_info["file_name"]
        label_name = fname.replace(".json", ".txt")

        src = f"{img_dir}/{img_name}"
        dst = f"{out_dir}/images/{img_name}"
        if os.path.exists(src):
            shutil.copy(src, dst)

        lines = []
        for ann in data["annotations"]:
            seg = ann["segmentation"]

            # ✅ to'g'ri yo'l: decode qilib binary mask olish
            rle = {
                "counts": seg["counts"].encode("ascii"),
                "size": seg["size"]
            }
            binary_mask = maskUtils.decode(rle)  # frPyObjects siz!

            if binary_mask.ndim == 3:
                binary_mask = binary_mask[:, :, 0]

            contours, _ = cv2.findContours(
                binary_mask.astype(np.uint8),
                cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE
            )
            if not contours:
                continue

            contour = max(contours, key=cv2.contourArea)
            if len(contour) < 3:
                continue

            points = contour.reshape(-1, 2)
            coords = []
            for x, y in points:
                coords.extend([x / W, y / H])

            line = "0 " + " ".join(f"{c:.6f}" for c in coords)
            lines.append(line)

        with open(f"{out_dir}/labels/{label_name}", "w") as f:
            f.write("\n".join(lines))

    print(f"{split} done!")

convert_to_yolo("train")
convert_to_yolo("valid")
convert_to_yolo("test")
print("Hammasi tayyor!")