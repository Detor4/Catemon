from ultralytics import YOLO

model = YOLO("yolov8n-seg.pt")

model.train(
    data="yolo_dataset/data.yaml",
    epochs=50,
    imgsz=640,
    batch=16,
    name="cat_seg_model",
    device=0
)