# DB Puller

[English](README.md) | [Bahasa Indonesia](README.id.md)

CLI interaktif untuk mengunduh database SQLite dari aplikasi Android melalui ADB — pilih perangkat, aplikasi, dan database menggunakan `fzf`, serta dapatkan pemeriksaan integritas instan tanpa perlu mengetik perintah `adb shell run-as` secara manual.

<img width="1120" height="1071" alt="screenshot" src="https://github.com/user-attachments/assets/5ac83c1c-c436-4630-a938-9cdb9dff14dd" />

## Mengapa Memakai DB Puller?

Mengekstrak dan memeriksa database SQLite aplikasi di Android biasanya membutuhkan serangkaian perintah manual yang panjang: mencari nomor seri perangkat, mencari package name aplikasi, menjalankan `run-as`, mencetak isi database (`cat`), mengalihkan ke file lokal, lalu memeriksa isinya dengan `sqlite3`. DB Puller menyederhanakan seluruh alur tersebut menjadi satu perintah interaktif yang cepat.

## Fitur

- Mendeteksi perangkat ADB yang terhubung secara otomatis (atau memilih jika lebih dari satu perangkat terhubung)
- Pencarian fuzzy untuk aplikasi terinstal (`fzf`) tanpa perlu menelusuri daftar package yang panjang
- Menampilkan daftar database SQLite yang valid di dalam aplikasi secara otomatis (mengabaikan file `-journal`, `-wal`, `-shm`)
- Menampilkan progress bar saat proses unduh berlangsung
- Pemeriksaan integritas otomatis (`PRAGMA integrity_check`) dan penghitungan jumlah tabel setelah selesai
- Opsi untuk mencadangkan file lama dengan timestamp jika file dengan nama yang sama sudah ada

---

## Prasyarat & Panduan Pengaturan

### 1. Instalasi Alat yang Dibutuhkan

Pastikan `adb` dan `fzf` sudah terpasang di komputer Anda:

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
  - Instal via [Scoop](https://scoop.sh/): `scoop install adb fzf sqlite`
  - Atau unduh [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) dan tambahkan ke `PATH`.

---

### 2. Mengaktifkan USB Debugging di Android

Jika Anda baru pertama kali menghubungkan HP Android untuk debugging, ikuti langkah-langkah berikut:

#### Langkah 1: Aktifkan Opsi Pengembang (Developer Options)
1. Buka **Pengaturan (Settings)** di HP Android Anda.
2. Masuk ke **Tentang Ponsel (About Phone)** (atau *Pengaturan > Sistem > Tentang Ponsel*).
3. Cari menu **Nomor Bentukan (Build Number)** dan ketuk/tap sebanyak **7 kali** berturut-turut hingga muncul pesan: *"Anda sekarang adalah seorang pengembang!"*.

#### Langkah 2: Nyalakan USB Debugging
1. Kembali ke **Pengaturan** > **Sistem** > **Opsi Pengembang (Developer Options)** (atau *Pengaturan Tambahan > Opsi Pengembang* pada Xiaomi/Oppo/Realme).
2. Aktifkan **Opsi Pengembang**.
3. Gulir ke bagian **Debugging** dan aktifkan **USB Debugging**.
   > *Catatan khusus pengguna Xiaomi / HyperOS / MIUI:* Aktifkan juga **USB Debugging (Security Settings)** jika diminta.

#### Langkah 3: Hubungkan ke Komputer & Beri Izin
1. Hubungkan HP Android ke komputer menggunakan kabel USB.
2. Ubah mode koneksi USB dari *Hanya Mengisi Daya* ke *Transfer File / MTP* jika diperlukan.
3. Dialog pop-up akan muncul di layar HP: **"Izinkan USB debugging?" / "Allow USB debugging?"**.
4. Centang opsi **"Selalu izinkan dari komputer ini"** dan pilih **Izinkan (Allow)**.

#### Langkah 4: Verifikasi Koneksi ADB
Buka terminal di komputer Anda dan jalankan:
```bash
adb devices
```
Perangkat Anda harus terdaftar dengan status `device` (bukan `unauthorized` atau `offline`):
```text
List of devices attached
0123456789ABCDEF    device
```

---

### 3. Ketentuan Aplikasi

Untuk mengekstrak database SQLite menggunakan perintah `adb shell run-as`:
- **Untuk HP Non-Root:** Aplikasi target harus dibuat dalam mode debug (misalnya `debuggable="true"` di `AndroidManifest.xml` atau di-build via `./gradlew assembleDebug`).
- **Untuk HP Rooted:** Dapat membaca aplikasi apa saja.

---

## Instalasi

Jalankan perintah instalasi satu baris:

```bash
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/install.sh | bash
```

Atau instal secara manual:

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Payaman-Studio/db-puller/main/db-puller.sh -o ~/.local/bin/db-puller
chmod +x ~/.local/bin/db-puller
```

*(Pastikan direktori `~/.local/bin` sudah terdaftar di `PATH` shell Anda)*

---

## Cara Penggunaan

```bash
db-puller
```

Ikuti petunjuk interaktif di terminal:
1. **Pilih Perangkat** (jika ada lebih dari 1 perangkat/emulator yang terhubung)
2. **Cari & Pilih Aplikasi** (pencarian fuzzy nama package)
3. **Pilih Database** (pilih file SQLite yang ingin diunduh)
4. **Unduh & Periksa** (progress bar + pemeriksaan integritas & ringkasan jumlah tabel otomatis)

File database yang ditarik akan tersimpan di direktori kerja terminal Anda saat ini.

---

## Pemecahan Masalah (Troubleshooting)

- **Status perangkat `unauthorized`**: Cabut kabel USB, pasang kembali, buka kunci layar HP, dan setujui dialog "Izinkan USB debugging".
- **Pesan error `run-as: package not debuggable`**: Aplikasi yang dipilih adalah build rilis/produksi tanpa atribut `debuggable="true"`. Pasang build debug atau gunakan perangkat yang sudah di-root.
- **Database tidak ditemukan**: Pastikan aplikasi sudah pernah dibuka minimal sekali di HP agar file database telah dibuat.

---

## Lisensi

MIT
