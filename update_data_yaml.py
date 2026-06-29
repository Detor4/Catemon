"""data.yaml ni 2 klassli (cat + other) formatga yangilash."""
from pathlib import Path

yaml_path = Path("yolo_dataset/data.yaml")
content = """path: /home/detor/Main/ML/Projects/CatDetectorGame/yolo_dataset
train: train/images
val: valid/images
test: test/images

nc: 2
names: ['cat', 'other']
"""
yaml_path.write_text(content)
print(f"Yangilandi: {yaml_path}")
