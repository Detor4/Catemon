"""YOLO modelini mobil ilova uchun ONNX ga eksport qilish (opset 12, 320x320)."""
import shutil
from pathlib import Path

from ultralytics import YOLO

WEIGHTS = "runs/segment/cat_other_model-4/weights/best.pt"
OUT_ASSET = "cat_detector_app/assets/best.onnx"


def find_latest_weights() -> Path:
    runs = sorted(Path("runs/segment").glob("cat_other_model*/weights/best.pt"))
    if not runs:
        raise FileNotFoundError(
            "cat_other_model weights topilmadi. Avval train_finetune.py ni ishga tushiring."
        )
    return runs[-1]


def main():
    weights = find_latest_weights()
    print(f"Model: {weights}")

    model = YOLO(str(weights))
    exported = model.export(format="onnx", imgsz=320, opset=12, simplify=True)

    shutil.copy(exported, OUT_ASSET)
    print(f"Tayyor: {OUT_ASSET}")


if __name__ == "__main__":
    main()
