# DB Puller

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

## Requirements

- `adb` (Android Platform Tools), device with USB debugging enabled
- [`fzf`](https://github.com/junegunn/fzf)
- `sqlite3` (optional — used for integrity check and table count)
- Device must be rooted/debuggable, or the target app must be `debuggable="true"` (required by `run-as`)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/install.sh | bash
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/db-puller.sh -o /usr/local/bin/db-puller
chmod +x /usr/local/bin/db-puller
```

## Usage

```bash
db-puller
```

Follow the prompts: select a device → search & select an app → select a database → wait for the download to finish. The resulting file is saved in the directory you ran the command from.

## License

MIT
