# LifeOS — Your Personal Command Center

A native macOS app built with Flutter for managing your finances, goals, schedule, health, and notes — all in one sleek dark-themed interface.

![LifeOS Dashboard](https://img.shields.io/badge/platform-macOS-blue) ![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter) ![Release](https://img.shields.io/github/v/release/Dmrfun/ai-test)

---

## Features

| Module | Description |
|--------|-------------|
| 💰 **Budget** | Track balance, log expenses, view spending history |
| 🎯 **Goals** | Set goals with priorities and track progress |
| 📅 **Schedule** | Daily events, reminders, and weekly agenda |
| 💪 **Health** | Habit streaks, sleep logs, exercise tracker |
| 📓 **Notes** | Tagged notes, journal entries, full-text search |

---

## Download & Install (macOS)

### Step 1 — Download

Go to the [**Releases page**](https://github.com/Dmrfun/ai-test/releases/latest) and download **`lifeos.dmg`**.

### Step 2 — Mount and Install

1. Double-click **`lifeos.dmg`** to open it
2. Drag **`lifeos.app`** into your **Applications** folder

### Step 3 — Remove macOS Quarantine

Because the app is not yet notarized with Apple, macOS will block it from opening with a *"cannot be opened because it is from an unidentified developer"* warning. Run this one-time command in Terminal to remove the quarantine flag:

```bash
xattr -d com.apple.quarantine /Applications/lifeos.app
```

> **Alternative (no Terminal):** Right-click `lifeos.app` in Finder → click **Open** → click **Open** again in the dialog. macOS will remember your choice after the first time.

### Step 4 — Open the App

Launch **LifeOS** from your Applications folder or Spotlight (`⌘ Space` → type `lifeos`).

---

## Build from Source

### Requirements

- [Flutter 3.41+](https://docs.flutter.dev/get-started/install/macos)
- Xcode (for macOS target)
- macOS 12 Monterey or later

### Steps

```bash
# Clone the repo
git clone https://github.com/Dmrfun/ai-test.git
cd ai-test/lifeos_flutter

# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d macos

# Build release .app
flutter build macos --release
# Output: build/macos/Build/Products/Release/lifeos.app
```

---

## Project Structure

```
lifeos_flutter/
├── lib/
│   ├── main.dart               # Entry point
│   ├── models/                 # Data models (budget, goals, health, notes, schedule)
│   ├── screens/                # Full-page screens for each module
│   ├── widgets/                # Reusable UI components
│   └── theme/                  # Dark theme and colour palette
├── macos/                      # macOS platform runner
├── web/                        # Web platform (bonus target)
└── pubspec.yaml
```

---

## Data Storage

All data is stored locally using `shared_preferences`. Nothing leaves your device.
