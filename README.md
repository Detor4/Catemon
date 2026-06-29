<p align="center">
  <img src="cat_detector_app/docs/screenshots/01-home-profile.png" alt="Catemon" width="280" />
</p>

<h1 align="center">🐾 Catemon</h1>

<p align="center">
  <strong>Discover real cats. Build your collection. Level up your profile.</strong>
</p>

<p align="center">
  Flutter mobile game with on-device YOLO segmentation — detect cats, save transparent cutouts, grade rarity, and grow your collection.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-black" alt="Platform" />
  <img src="https://img.shields.io/badge/ML-ONNX%20Runtime-orange" alt="ONNX" />
</p>

---

## Home & Profile

<img src="cat_detector_app/docs/screenshots/01-home-profile.png" width="300" />

Your player hub: edit name and avatar, set a showcase cat, track level, power, and login streak. Bottom nav opens Collection, Camera, and Upgrade.

---

## Live Detection

<img src="cat_detector_app/docs/screenshots/02-camera-detection.png" width="300" />

Point the camera at a cat. After 2 confirmed frames, tap capture to save a segmented cutout. You can also pick an image from the gallery.

---

## Collection

<img src="cat_detector_app/docs/screenshots/03-gallery.png" width="300" />

Grid of all saved cats with rarity badges and dates. Tap to view, long-press to delete.

---

## Cat Viewer (Fullscreen)

<img src="cat_detector_app/docs/screenshots/04-cat-view-fullscreen.png" width="300" />

Swipe down on the panel to view the cat fullscreen. Drag to rotate, pinch to zoom.

---

## Cat Details

<img src="cat_detector_app/docs/screenshots/05-cat-view-details.png" width="300" />

Swipe up to see rarity, accuracy, coat color, quality, and capture date.

---

## Upgrade

<img src="cat_detector_app/docs/screenshots/06-upgrade.png" width="300" />

Pick a cat to upgrade, then sacrifice others of the same tier. The target cat is kept; sacrifices are consumed.

| From | To | Sacrifices |
|------|----|------------|
| Common | Common+ | 2 |
| Common+ | Uncommon | 2 |
| Uncommon | Rare | 2 |
| Rare | Epic | 3 |
| Epic | Legendary | 3 |
| Legendary | Mythic | 4 |

---

## Achievements

<img src="cat_detector_app/docs/screenshots/07-achievements.png" width="300" />

Six unlockable titles (first cat, 30 cats, 3 Legendary, 1 Mythic, level 10, 7-day streak). Earned titles stay forever.

---

## Settings

<img src="cat_detector_app/docs/screenshots/08-settings.png" width="300" />

Switch between Uzbek, Russian, and English. Changes apply instantly.

---

## Getting Started

```bash
cd cat_detector_app
flutter pub get
flutter run
```

## Build APK

```bash
cd cat_detector_app
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

---

<p align="center">
  Made with 🐾 and Flutter · <strong>Catemon v1.0.0</strong>
</p>
