"""Mavjud mushuk modelidan fine-tuning: cat + other (2 klass)."""
from ultralytics import YOLO

BASE_MODEL = "runs/segment/cat_seg_model-2/weights/best.pt"
DATA = "yolo_dataset/data.yaml"

model = YOLO(BASE_MODEL)
model.train(
    data=DATA,
    epochs=30,
    imgsz=640,
    batch=16,
    lr0=0.001,
    name="cat_other_model",
    device=0,
)
