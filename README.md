# DB Puller

[English](README.md) | [Bahasa Indonesia](README.id.md)

Interactive CLI to pull SQLite databases from Android apps via ADB — pick device, app, and database with `fzf`, and get an instant integrity check without typing `adb shell run-as` commands by hand.

<img width="1120" height="1071" alt="screenshot" src="https://github.com/user-attachments/assets/5ac83c1c-c436-4630-a938-9cdb9dff14dd" />

## Why

Debugging app data on Android usually means a chain of manual commands: find the device serial, find the package name, `run-as`, `cat` the database, redirect it to a local file, then check its contents with `sqlite3`. DB Puller wraps all of that into a single interactive command.

## Features

- Auto-detects connected ADB devices, or lets you pick when more than one is connected
- Fuzzy-search installed apps (`fzf`) instead of scrolling a raw package list
- Auto-lists valid databases inside the app (skips `-journal`, `-wal`, `-shm` files)
- Real-time progress bar during download
- Automatic integrity check (`PRAGMA integrity_check`) and table count after completion
- Option to back up the existing file with a timestamp if one already exists

## Prerequisites & Setup Guide

### 1. Install Required Tools

Make sure you have `adb` and `fzf` installed on your machine:

- **macOS (Homebrew):**
  ```bash
  brew install android-platform-tools fzf sqlite
  ```
- **Ubuntu / Debian:**
  ```bash
  sudo apt update && sudo apt install adb fzf sqlite3
  ```
- **Arch Linux:**
  ```bash
  sudo pacman -S android-tools fzf sqlite
  ```
- **Windows:**
  - Install via [Scoop](https://scoop.sh/): `scoop install adb fzf sqlite`
  - Or download [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) and add it to your `PATH`.

---

### 2. Enable USB Debugging on Android

If you are setting up your Android device for the first time, follow these steps:

#### Step 1: Enable Developer Options
1. Open **Settings** on your Android device.
2. Go to **About Phone** (or *Settings > System > About Phone*).
3. Find **Build Number** and tap it **7 times** consecutively until you see the message: *"You are now a developer!"*.

#### Step 2: Turn on USB Debugging
1. Go back to **Settings** > **System** > **Developer Options** (or *Additional Settings > Developer Options* on Xiaomi/Oppo/Realme).
2. Toggle on **Developer Options**.
3. Scroll down to the **Debugging** section and toggle on **USB Debugging**.
   > *Note for Xiaomi / HyperOS / MIUI users:* Also enable **USB Debugging (Security Settings)** if prompted.

#### Step 3: Connect to Computer & Authorize
1. Connect your Android device to your computer via USB cable.
2. Change USB mode from *Charge only* to *File Transfer / MTP* if needed.
3. A popup prompt will appear on your phone: **"Allow USB debugging?"**.
4. Check **"Always allow from this computer"** and tap **Allow**.

#### Step 4: Verify ADB Connection
Open your terminal and run:
```bash
adb devices
```
You should see your device listed with status `device` (not `unauthorized` or `offline`):
```text
List of devices attached
0123456789ABCDEF    device
```

---

### 3. App Requirements

To pull SQLite databases using `adb shell run-as`:
- **For Non-Rooted Devices:** The target application must be built in debug mode (e.g. `debuggable="true"` in `AndroidManifest.xml` or generated via `./gradlew assembleDebug`).
- **For Rooted Devices:** Works with any app.

---

## Installation

Run the one-line installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/install.sh | bash
```

Or install manually:

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/db-puller.sh -o ~/.local/bin/db-puller
chmod +x ~/.local/bin/db-puller
```

*(Make sure `~/.local/bin` is in your shell `PATH`)*

---

## Usage

```bash
db-puller
```

Follow the interactive prompts:
1. **Select Device** (if multiple devices/emulators are connected)
2. **Search & Select App** (fuzzy-search package names)
3. **Select Database** (choose the SQLite database file to pull)
4. **Download & Check** (progress bar + automatic integrity check & table summary)

The extracted database file will be saved in your current working directory.

---

## Troubleshooting

- **Device listed as `unauthorized`**: Unplug the USB cable, plug it back in, unlock your phone, and accept the "Allow USB debugging" prompt.
- **`run-as: package not debuggable`**: The selected application is a production / release build without `debuggable="true"`. Install a debug build or use a rooted device.
- **No databases found**: Ensure the app has been opened at least once on the device so it can create its database files.

---

## License

MIT

