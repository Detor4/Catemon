<p align="center">
  <img src="docs/screenshots/01-home-profile.png" alt="Catemon" width="280" />
</p>

<h1 align="center">🐾 Catemon</h1>

<p align="center">
  <strong>Discover real cats. Build your collection. Level up your profile.</strong>
</p>

<p align="center">
  A Flutter mobile game that uses on-device YOLO segmentation to detect cats through your camera,
  extract them as transparent PNG cutouts, grade their rarity, and grow a personal cat collection.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-black" alt="Platform" />
  <img src="https://img.shields.io/badge/ML-ONNX%20Runtime-orange" alt="ONNX" />
  <img src="https://img.shields.io/badge/Version-1.0.0-blue" alt="Version" />
</p>

---

## Table of Contents

- [Screenshots](#screenshots)
- [Features](#features)
- [How to Use](#how-to-use)
- [Rarity System](#rarity-system)
- [Upgrade Rules](#upgrade-rules)
- [Player Progression](#player-progression)
- [Achievements](#achievements)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Build APK](#build-apk)
- [Project Structure](#project-structure)

---

## Screenshots

<table>
  <tr>
    <td align="center"><b>Profile & Home</b><br/><img src="docs/screenshots/01-home-profile.png" width="220" /></td>
    <td align="center"><b>Live Detection</b><br/><img src="docs/screenshots/02-camera-detection.png" width="220" /></td>
    <td align="center"><b>Collection</b><br/><img src="docs/screenshots/03-gallery.png" width="220" /></td>
  </tr>
  <tr>
    <td align="center"><b>Cat View (Fullscreen)</b><br/><img src="docs/screenshots/04-cat-view-fullscreen.png" width="220" /></td>
    <td align="center"><b>Cat Details</b><br/><img src="docs/screenshots/05-cat-view-details.png" width="220" /></td>
    <td align="center"><b>Upgrade</b><br/><img src="docs/screenshots/06-upgrade.png" width="220" /></td>
  </tr>
  <tr>
    <td align="center"><b>Achievements</b><br/><img src="docs/screenshots/07-achievements.png" width="220" /></td>
    <td align="center" colspan="2"><b>Settings & Languages</b><br/><img src="docs/screenshots/08-settings.png" width="220" /></td>
  </tr>
</table>

---

## Features

### 📷 Real-Time Cat Detection
- Point your camera at a cat and get **live bounding boxes** with corner-bracket overlays
- Multi-cat support — detects and counts all visible cats
- Confidence score displayed when a cat is confirmed
- Scan line animation while searching

### ✂️ Background Removal (Segmentation)
- After capture, YOLOv8 **segmentation** extracts the cat from the photo
- Saves a **transparent PNG cutout** — no background, just the cat
- If multiple cats are in frame, automatically picks the **best** one (confidence + mask quality)

### 🖼️ Gallery Import
- Pick any image from your phone gallery
- App runs detection — if a cat is found, it processes and saves; if not, shows **"No cat found"**

### ⭐ Rarity Grading System
Each captured cat is graded based on three factors:
1. **Image quality** — sharpness, resolution, coverage
2. **Detection confidence** — how certain the model is it's a cat
3. **Fur color analysis** — dominant coat color mapped to rarity tiers

Balanced grading — not everything is Common or Mythic.

### 🎴 Collection Gallery
- Grid view of all your cat cutouts
- Rarity-colored borders, star ratings, and timestamps
- Tap to open the interactive 3D-style viewer
- Long-press to delete

### 🌀 Interactive Cat Viewer
- **Swipe down** on the info panel → cat goes fullscreen
- **Swipe up** → panel expands with stats
- Rotate and zoom the 2D cutout with touch gestures (3D tilt effect)
- View accuracy, color, quality, and capture date

### ⚡ Upgrade System
- Select a cat you want to level up
- Sacrifice other cats of the **same rarity** (the target cat cannot be used as sacrifice)
- Fusion animation + new higher-tier cat

### 👤 Player Profile
- Custom **username** and **avatar**
- **Showcase cat** — display your favorite cat on the home screen
- **Player Level** powered by collection power (rarer cats = more XP)
- Daily login **streak** tracking

### 🏆 Achievements & Titles
- 6 unlockable achievements with progress bars
- Earned titles are **permanent** — never lost
- Set any earned title as your active profile badge

### 🌍 Multi-Language Support
- **Uzbek**, **Russian**, and **English**
- Change language instantly in Settings

### 🎨 Dark Game UI
- CatchCat-inspired dark aesthetic with neon orange accents
- Smooth animations via `flutter_animate`
- Offline Google Fonts bundled in assets

---

## How to Use

### 1. Home Screen (Profile)

<p align="center">
  <img src="docs/screenshots/01-home-profile.png" width="300" />
</p>

| Action | How |
|--------|-----|
| Edit your name | Tap the username → enter new name → Save |
| Change avatar | Tap the profile photo circle → pick from gallery |
| Set showcase cat | Tap the large cat frame → choose from your collection |
| View stats | See total cats, power, and login streak |
| Open achievements | Tap **Achievements** card or trophy icon (top right) |
| Open settings | Tap gear icon (top right) |

**Bottom navigation:**
- **Collection** (left) → your cat gallery
- **Camera** (center, orange button) → live detection
- **Upgrade** (right) → fuse cats to higher tiers

---

### 2. Capture a Cat (Camera)

<p align="center">
  <img src="docs/screenshots/02-camera-detection.png" width="300" />
</p>

1. Tap the **center camera button** on the home screen
2. Point your camera at a real cat
3. Wait for the status badge to show **"N cats!"** (green) — takes ~2 consecutive frames
4. Tap the **teal capture button** to take a photo
5. App automatically navigates to the gallery and processes the cutout

**Gallery import (from camera screen):**
- Tap the **gallery icon** (bottom left or top right)
- Select an image from your phone
- If a cat is detected → processing starts
- If no cat → you'll see a "No cat found" message

**Tips:**
- Good lighting improves detection accuracy
- Hold steady until the capture button pulses green
- One cat in frame gives the best cutout quality

---

### 3. Browse Your Collection

<p align="center">
  <img src="docs/screenshots/03-gallery.png" width="300" />
</p>

1. Tap **Collection** in the bottom nav (or from home)
2. Each card shows: cat image, rarity badge, stars, and date
3. **Tap** a card → open interactive viewer
4. **Long-press** a card → delete confirmation

While a new cat is being processed, you'll see a loading overlay:
*"Extracting cat… removing background, calculating grade"*

---

### 4. View & Interact with a Cat

<p align="center">
  <img src="docs/screenshots/04-cat-view-fullscreen.png" width="280" />
  &nbsp;&nbsp;
  <img src="docs/screenshots/05-cat-view-details.png" width="280" />
</p>

| Gesture | Result |
|---------|--------|
| Swipe **down** on panel | Panel collapses → cat fills the screen |
| Swipe **up** / tap **Info ▲** | Panel expands with full stats |
| Single finger drag | Rotate cat (3D tilt) |
| Pinch | Zoom in/out |
| ↻ button (top right) | Reset rotation and zoom |
| **Delete** | Remove cat from collection |
| **Share** | Coming soon |

**Stats shown:**
- Rarity name + stars
- Color quality progress bar
- Accuracy %, coat color, image quality %, capture date

---

### 5. Upgrade Cats

<p align="center">
  <img src="docs/screenshots/06-upgrade.png" width="300" />
</p>

1. Tap **Upgrade** in the bottom nav
2. **Step 1:** Tap the cat you want to upgrade (appears in the top slot)
3. **Step 2:** System auto-filters cats of the same rarity as sacrifices
4. Select the required number of sacrifice cats (cannot include the target cat)
5. Tap the upgrade button when `N/N selected` is complete
6. Sacrifice cats are deleted; your target cat levels up

**Example:** Upgrade Common → Common+ requires **2 other Common cats** besides the one you're upgrading.

---

### 6. Achievements

<p align="center">
  <img src="docs/screenshots/07-achievements.png" width="300" />
</p>

| Achievement | Requirement |
|-------------|-------------|
| Beginner | Collect your first cat |
| Collector | Own 30 cats |
| Legend Master | Collect 3 Legendary cats |
| Mythic Owner | Collect 1 Mythic cat |
| Veteran | Reach player level 10 |
| Loyal Player | Log in 7 days in a row |

- Tap **Set as Title** on any earned achievement to display it on your profile
- Tap again to remove the active title

---

### 7. Settings

<p align="center">
  <img src="docs/screenshots/08-settings.png" width="300" />
</p>

- Choose language: **O'zbekcha** / **Русский** / **English**
- Language changes apply immediately across the entire app
- View app version info

---

## Rarity System

| Tier | Stars | Color | Frequency |
|------|-------|-------|-----------|
| Common | ⭐ | Brown Tabby | Very common |
| Common+ | ⭐⭐ | Orange / Ginger | Common |
| Uncommon | ⭐⭐⭐ | Black | Uncommon |
| Rare | ⭐⭐⭐⭐ | Gray / Blue | Rare |
| Epic | ⭐⭐⭐⭐⭐ | White | Very rare |
| Legendary | 🌟 | Calico | Extremely rare |
| Mythic | ✨ | Tortoiseshell | Ultra rare |

Grading considers image quality, detection confidence, and fur color analysis with balanced distribution.

---

## Upgrade Rules

| From | To | Sacrifices Needed |
|------|----|-------------------|
| Common | Common+ | 2 × Common |
| Common+ | Uncommon | 2 × Common+ |
| Uncommon | Rare | 2 × Uncommon |
| Rare | Epic | 3 × Rare |
| Epic | Legendary | 3 × Epic |
| Legendary | Mythic | 4 × Legendary |

> The cat you are upgrading is **kept**. Only the sacrifice cats are consumed.

---

## Player Progression

Your **player level** is calculated from collection **power**:

| Rarity | Power Points |
|--------|-------------|
| Common | 1 |
| Common+ | 2 |
| Uncommon | 4 |
| Rare | 8 |
| Epic | 16 |
| Legendary | 60 |
| Mythic | 150 |

> **1 Legendary (60 pts) > 3 Epic (48 pts)** — rare cats significantly boost your level.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.12+ |
| ML Inference | ONNX Runtime (`onnxruntime`) |
| Model | YOLOv8 Segmentation (`best.onnx`) |
| Camera | `camera` package |
| Image Processing | `image` package |
| Storage | `path_provider` + JSON metadata |
| UI / Animation | `flutter_animate`, `google_fonts`, `shimmer` |
| Gallery Pick | `image_picker` |

All inference runs **on-device** — no internet required for detection.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.12+
- Android Studio / Xcode (for mobile builds)
- A physical device with a camera (recommended for testing)

### Install & Run

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/Catemon.git
cd Catemon/cat_detector_app

# Install dependencies
flutter pub get

# Run on connected device
flutter devices
flutter run
```

### First Launch

On first start the app loads:
1. The ONNX segmentation model (`assets/best.onnx`)
2. Your saved cat collection from local storage
3. Player profile and achievements

---

## Build APK

```bash
# Release APK (for distribution)
flutter build apk --release

# Output:
# build/app/outputs/flutter-apk/app-release.apk
```

```bash
# Smaller per-architecture APKs
flutter build apk --split-per-abi --release
```

```bash
# Install directly to connected phone
flutter install --release
```

---

## Project Structure

```
cat_detector_app/
├── assets/
│   ├── best.onnx              # YOLOv8 segmentation model
│   └── google_fonts/          # Offline bundled fonts
├── docs/
│   └── screenshots/           # App screenshots for README
├── lib/
│   ├── main.dart              # App entry point
│   ├── home_page.dart         # Profile & home screen
│   ├── camera_page.dart       # Live detection & capture
│   ├── gallery_page.dart      # Collection grid
│   ├── cat_play_view.dart     # Interactive cat viewer
│   ├── upgrade_page.dart      # Cat fusion / upgrade
│   ├── achievements_page.dart # Titles & rewards
│   ├── settings_page.dart     # Language settings
│   ├── yolo_detector.dart     # ONNX inference & mask parsing
│   ├── cat_grade.dart         # Rarity grading logic
│   ├── cat_photo_store.dart   # Local persistence
│   ├── profile_store.dart     # Player profile & XP
│   └── theme/                 # Colors, typography, design system
└── pubspec.yaml
```

---

## License

This project is for educational and personal use.  
Model weights and dataset sources belong to their respective owners.

---

<p align="center">
  Made with 🐾 and Flutter &nbsp;·&nbsp; <strong>Catemon v1.0.0</strong>
</p>
