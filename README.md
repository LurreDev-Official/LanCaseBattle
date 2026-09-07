# LanCast

Open-source local-network multi-device screen sharing (Flutter) — **LanCast Arena**.

Controlled room access: senders request join → room admin approves → WebRTC screen share on LAN.

---

## 🆕 Tutorial untuk Pengguna Baru

> Belum pernah pakai LanCast? Pilih platform kamu di bawah dan ikuti langkah-langkahnya.

### Apa itu LanCast?

LanCast memungkinkan kamu berbagi layar antar perangkat dalam **satu jaringan Wi-Fi / LAN** — tanpa internet, tanpa akun, tanpa cloud.

Ada **2 peran** dalam satu sesi LanCast:

| Peran | Aplikasi | Cocok untuk |
|-------|----------|-------------|
| 🖥️ **Arena (Host)** | LanCast Arena | Perangkat yang **menerima** tampilan layar — biasanya laptop/PC |
| 📱 **Participant (Sender)** | LanCast Participant | Perangkat yang **mengirim** layarnya — bisa laptop, PC, atau Android |

> **Semua perangkat harus tersambung ke Wi-Fi / LAN yang sama.**

---

## 🍎 Tutorial — macOS (Arena + Participant)

> Ikuti panduan ini jika kamu menjalankan LanCast di **MacBook atau Mac**.

### Prasyarat macOS

- [ ] macOS 12 Monterey atau lebih baru
- [ ] [Flutter 3.x](https://docs.flutter.dev/get-started/install/macos) terinstall
- [ ] Xcode Command Line Tools: `xcode-select --install`
- [ ] Git terinstall (`git --version` untuk cek)

**Setup satu kali:**

```bash
# Tambahkan Flutter ke PATH (jika muncul 'command not found: flutter')
export PATH="$HOME/development/flutter_backup_old/bin:$PATH"

# Aktifkan Flutter macOS desktop
flutter config --enable-macos-desktop

# Verifikasi (pastikan tidak ada error merah ✗)
flutter doctor
```

### Setup Proyek (macOS)

```bash
# Clone repo
git clone <URL_REPO_INI>
cd LanCaseBattle

# Install dependensi
dart pub get
```

### Menjalankan (macOS)

**Cara termudah — double-click:**

Buka Finder → cari file **`LanCast.command`** di folder proyek → double-click.

Dua jendela akan terbuka otomatis: **LanCast Arena** + **LanCast Participant**.

**Atau lewat Terminal:**

```bash
make run
```

### Izin Akses macOS (wajib untuk Participant)

Saat pertama kali membuka LanCast Participant, macOS akan meminta izin:

1. Buka **System Settings** → **Privacy & Security** → **Screen Recording**
2. Aktifkan toggle untuk **LanCast Participant** ✅
3. Jika muncul dialog **Local Network** → klik **Allow** untuk kedua aplikasi

> ⚠️ Tanpa izin Screen Recording, layar tidak bisa dibagikan ke Arena.

### Cara Akses & Penggunaan (macOS)

1. **Buka Aplikasi**:
   Jalankan `make run` di Terminal atau double-click `LanCast.command`. Dua jendela akan terbuka secara bersamaan: **LanCast Arena (Viewer)** dan **LanCast Participant (Sender)**.

2. **Akses & Inisialisasi Arena (Host/Viewer)**:
   - **LanCast Arena** secara otomatis membuat Battle Room baru (konfigurasi `LANCAST_AUTO_ROOM=true`).
   - Server lokal berjalan secara otomatis di port TCP **`17890`** (Signaling) dan UDP **`17891`** (Room Discovery).
   - Di layar Arena akan ditampilkan **Room ID**, **PIN Join**, serta status listener server.

3. **Menghubungkan Participant (Sender)**:
   - **Pencarian Otomatis**: Pada jendela **LanCast Participant**, klik tombol **Find Battle Room**. Room Arena yang aktif akan otomatis muncul via scanning UDP lokal. Klik room tersebut.
   - **Koneksi Manual (Via Link/IP)**: Jika room tidak terdeteksi otomatis, klik tombol **Join via Link / Manual IP** di Participant, lalu masukkan link/IP yang tertera di layar Arena (misal: `ws://<IP_Mac_Host>:17890`).

4. **Approval & Screen Share**:
   - Di jendela **Participant**, klik **Request Join**.
   - Di jendela **Arena**, akan muncul notifikasi permintaan bergabung. Klik **Approve**.
   - Di jendela **Participant**, tombol **Start Share** akan aktif. Klik **Start Share** untuk mulai membagikan layar secara real-time 🎉

### Troubleshooting macOS

| Masalah | Solusi |
|---------|--------|
| Room tidak muncul di Participant | Pastikan kedua app di Wi-Fi yang sama |
| Layar tidak muncul di Arena | System Settings → Screen Recording → aktifkan Participant |
| Gatekeeper memblokir app | Jalankan: `xattr -dr com.apple.quarantine "NamaApp.app"` |
| `flutter` tidak ditemukan | Set `FLUTTER_BIN=/path/ke/flutter/bin` di `config/lancast.env` |
| Join gagal | Buka TCP port **17890** di firewall/router |

### Menghentikan Sesi (macOS)

```bash
make stop
```

Atau tutup kedua jendela app secara manual.

---

## 🪟 Tutorial — Windows (Arena + Participant)

> Ikuti panduan ini jika kamu menjalankan LanCast di **PC Windows**.

### Prasyarat Windows

- [ ] Windows 10 (64-bit) versi 1903 atau lebih baru
- [ ] [Flutter 3.x for Windows](https://docs.flutter.dev/get-started/install/windows) terinstall
- [ ] **Visual Studio 2022** dengan workload **Desktop development with C++** ([download](https://visualstudio.microsoft.com/))
- [ ] Git for Windows ([download](https://git-scm.com/download/win))

**Setup satu kali — jalankan di PowerShell atau CMD:**

```powershell
# Aktifkan Flutter Windows desktop
flutter config --enable-windows-desktop

# Verifikasi (pastikan tidak ada error merah ✗)
flutter doctor
```

> ⚠️ Jika `flutter doctor` menunjukkan Visual Studio tidak ditemukan, pastikan workload **Desktop development with C++** sudah terinstall di Visual Studio Installer.

### Setup Proyek (Windows)

```powershell
# Clone repo (di PowerShell atau CMD)
git clone <URL_REPO_INI>
cd LanCaseBattle

# Install dependensi
dart pub get
```

### Menjalankan (Windows)

**Cara termudah — double-click:**

Buka File Explorer → cari file **`LanCast.bat`** di folder proyek → double-click.

Dua jendela CMD akan terbuka, masing-masing menjalankan **Arena** dan **Participant**.

**Atau lewat PowerShell manual:**

```powershell
# Terminal 1 — Arena
cd apps\viewer
flutter run -d windows --dart-define=AUTO_ROOM=true

# Terminal 2 — Participant (buka terminal baru)
cd apps\sender
flutter run -d windows
```

### Izin Akses Windows (wajib)

Saat pertama kali dijalankan, Windows Firewall akan menampilkan popup:

1. Klik **Allow access** untuk LanCast Arena dan LanCast Participant
2. Pastikan port berikut tidak diblokir:
   - UDP **17891** → untuk discovery room
   - TCP **17890** → untuk koneksi signaling

**Jika popup tidak muncul, tambahkan manual:**

Buka **Windows Defender Firewall** → **Advanced Settings** → **Inbound Rules** → **New Rule** → Port → masukkan `17890` (TCP) dan `17891` (UDP).

### Cara Akses & Penggunaan (Windows)

1. **Buka Aplikasi**:
   Double-click `LanCast.bat` di File Explorer (atau jalankan script via PowerShell/CMD). Dua jendela CMD dan aplikasi akan terbuka secara bersamaan: **LanCast Arena (Viewer)** dan **LanCast Participant (Sender)**.

2. **Akses & Inisialisasi Arena (Host/Viewer)**:
   - **LanCast Arena** secara otomatis membuat Battle Room baru.
   - Server lokal otomatis mendengarkan koneksi di port TCP **`17890`** (Signaling WebSocket) dan UDP **`17891`** (Room Discovery).
   - Di layar Arena akan ditampilkan **Room ID**, **PIN Join**, serta status listener server.

3. **Menghubungkan Participant (Sender)**:
   - **Pencarian Otomatis**: Pada jendela **LanCast Participant**, klik tombol **Find Battle Room**. Room Arena yang aktif akan otomatis muncul via scanning UDP lokal. Klik room tersebut.
   - **Koneksi Manual (Via Link/IP)**: Jika room tidak terdeteksi otomatis, klik tombol **Join via Link / Manual IP** di Participant, lalu masukkan link/IP yang tertera di layar Arena (misal: `ws://<IP_Windows_Host>:17890`).

4. **Approval & Screen Share**:
   - Di jendela **Participant**, klik **Request Join**.
   - Di jendela **Arena**, akan muncul notifikasi permintaan bergabung. Klik **Approve**.
   - Di jendela **Participant**, tombol **Start Share** akan aktif. Klik **Start Share** untuk mulai membagikan layar secara real-time 🎉

### Troubleshooting Windows

| Masalah | Solusi |
|---------|--------|
| Room tidak muncul | Pastikan kedua app di Wi-Fi yang sama; cek firewall UDP 17891 |
| Build gagal / error C++ | Install Visual Studio 2022 + workload *Desktop development with C++* |
| `flutter` tidak dikenal | Tambahkan Flutter ke PATH, atau set `FLUTTER_BIN` di `config\lancast.env` |
| Join gagal | Buka TCP port **192.168.1.244:17890** di Windows Firewall |
| `make` tidak dikenal | Gunakan perintah manual di [`docs/RUN.md`](docs/RUN.md) atau install `make` via [Chocolatey](https://chocolatey.org/): `choco install make` |

### Menghentikan Sesi (Windows)

Tutup kedua jendela CMD / PowerShell yang menjalankan Arena dan Participant.

Atau jika menggunakan Makefile (via Chocolatey make):

```bash
make stop
```

---

## 🤖 Tutorial — Android (Participant / Sender saja)

> Ikuti panduan ini jika kamu ingin **mengirim layar Android** ke Arena di laptop/PC.

> **Catatan:** Android hanya bisa berperan sebagai **Participant (Sender)**. Arena (host) harus tetap di laptop/PC (macOS atau Windows).

### Prasyarat Android

- [ ] Android 8.0 (API level 26) atau lebih baru
- [ ] **Developer Options** aktif di perangkat Android
- [ ] USB Debugging aktif (untuk build dari laptop) — atau gunakan APK yang sudah di-build
- [ ] Di laptop: Flutter + Android SDK terinstall

**Cek Flutter Android setup di laptop:**

```bash
flutter doctor
```

Pastikan baris **Android toolchain** tidak merah.

### Setup Build APK (dari Laptop)

```bash
# Dari root proyek
cd apps/sender

# Build APK debug
flutter build apk --debug

# APK ada di:
# build/app/outputs/flutter-apk/app-debug.apk
```

Install APK ke Android via USB:

```bash
# Pastikan USB Debugging aktif, lalu:
flutter install -d <device-id>

# Lihat daftar device yang terhubung:
flutter devices
```

Atau copy file `app-debug.apk` ke Android dan install manual.

### Izin Akses Android (wajib)

Saat pertama kali membuka **LanCast Participant** di Android:

1. **Izin Screen Recording** → klik **Allow** saat diminta sistem
2. **Izin Local Network / Wi-Fi** → klik **Allow**

> ⚠️ Di Android 13+, izin mungkin muncul sebagai "Allow display over other apps" atau lewat **Media Projection**.

### Cara Pakai (Android sebagai Participant)

**Di laptop (Arena/host):**
1. Jalankan LanCast Arena (`make run` atau `LanCast.command` / `LanCast.bat`)
2. Room terbuat otomatis — **catat atau share link room**

**Di Android (Participant):**
1. Sambungkan ke **Wi-Fi yang sama** dengan laptop Arena
2. Buka **LanCast Participant** di Android
3. Klik **Find Battle Room** → room Arena akan muncul dalam list
4. Pilih room → klik **Request Join**

**Di laptop (Arena):**

5. Terima notifikasi join → klik **Approve**

**Di Android:**

6. Klik **Start Share** → izinkan Screen Recording → layar Android mulai dibagikan ke Arena 🎉

> 💡 Room tidak muncul di Android? Pastikan Wi-Fi sama, lalu coba **Join via Link** (paste link dari Arena).

### Troubleshooting Android

| Masalah | Solusi |
|---------|--------|
| Room tidak muncul | Pastikan HP di Wi-Fi yang **persis sama** dengan laptop Arena |
| `flutter devices` tidak tampilkan HP | Aktifkan USB Debugging di Developer Options |
| APK tidak bisa diinstall | Aktifkan "Install from unknown sources" di Settings Android |
| Layar tidak muncul di Arena | Izinkan Screen Recording saat popup muncul |
| Join gagal | Pastikan firewall laptop tidak memblokir TCP 17890 |

---

## 📊 Ringkasan Platform

| Fitur | macOS | Windows | Android |
|-------|-------|---------|---------|
| Sebagai Arena (host) | ✅ | ✅ | ❌ |
| Sebagai Participant | ✅ | ✅ | ✅ |
| Cara jalankan | `LanCast.command` / `make run` | `LanCast.bat` | Install APK |
| Screen Recording | System Settings | Otomatis | Izin saat buka app |
| Firewall | Tidak perlu konfigurasi | Buka port 17890/17891 | Tidak perlu |

---

### FAQ

**Q: Apakah LanCast butuh internet?**  
A: Tidak. LanCast bekerja 100% di jaringan lokal (LAN/Wi-Fi). Tidak ada data yang dikirim ke cloud.

**Q: Berapa banyak Participant yang bisa join?**  
A: Untuk MVP, satu room per Arena. Semua Participant harus di LAN yang sama.

**Q: Apakah iOS didukung?**  
A: Belum di MVP. Saat ini hanya macOS, Windows, dan Android.

**Q: Apakah Arena bisa berbagi layarnya ke Participant?**  
A: Tidak. Alur hanya **Participant → Arena** (Sender berbagi ke host).

**Q: Cara export app siap pakai (.app / .exe)?**  
A: `make export` (macOS) atau `.\\scripts\\export.ps1` (Windows). Hasil di folder `dist/`. Detail: [`docs/RUN.md`](docs/RUN.md).

---

## Petunjuk Cepat (Mac & Windows)

Dokumentasi lengkap menjalankan + mengekspor app: **[`docs/RUN.md`](docs/RUN.md)**

| Platform | Jalankan (dev) | Export (release) |
|----------|----------------|------------------|
| **macOS** | Double-click `LanCast.command` atau `make run` | `make export` → `dist/` |
| **Windows** | Double-click `LanCast.bat` | `.\scripts\export.ps1` → `dist\` |

## One-shot run (development)

```bash
# macOS / Linux
make run
```

Windows: double-click `LanCast.bat` atau lihat [`docs/RUN.md`](docs/RUN.md).

Konfigurasi: [`config/lancast.env`](config/lancast.env)

| Variable | Default | Arti |
|----------|---------|------|
| `LANCAST_DEVICE` | `macos` | Target `flutter run -d` (`windows` di PC Windows) |
| `LANCAST_AUTO_ROOM` | `true` | Viewer langsung buat room |
| `FLUTTER_BIN` | (auto) | Path ke Flutter SDK `bin` |

```bash
make run-manual   # tanpa auto-room
make run-apps     # buka .app debug yang sudah di-build (macOS)
make stop
make export       # build release → dist/
```

### Cursor / VS Code

Run & Debug → compound **`LanCast (Viewer + Sender)`** → Start (`F5`).

## Alur pakai

1. **LanCast Arena** (Viewer) buat battle room / auto room  
2. **Share Join Link** atau biarkan UDP discovery  
3. **LanCast Participant** (Sender) → Scan / Join via Link → Request Join  
4. Arena → **Approve**  
5. Participant → **Start Share** (izinkan Screen Recording di macOS)

## Structure

```
apps/viewer/                 # Arena / room admin + host
apps/sender/                 # Participant: discover, join, share
packages/lancast_*/          # core, discovery, signaling, webrtc, arena
config/lancast.env           # one-shot defaults
scripts/run.sh               # one-shot launcher
scripts/export.sh            # release export (macOS/Windows)
scripts/export.ps1           # release export (Windows PowerShell)
docs/RUN.md                  # petunjuk Mac & Windows
docs/agent/                  # AI agent playbooks
skilll.md                    # Product MVP spec (LAN)
skilll-cloud.md              # DRAFT skill: LanCast Cloud / Web online
dist/                        # hasil export (dihasilkan script)
```

## Dev commands

```bash
make deps
make test
make analyze
make export
```
