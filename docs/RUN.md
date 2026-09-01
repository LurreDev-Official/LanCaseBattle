# Menjalankan & Mengekspor LanCast (macOS / Windows)

LanCast terdiri dari **2 aplikasi**:

| App | Nama export | Peran |
|-----|-------------|--------|
| Viewer | **LanCast Arena** | Judge / host room / tampilan 4 layar |
| Sender | **LanCast Participant** | Peserta: join + screen share |

Keduanya harus di **LAN / Wi-Fi yang sama**.

---

## Prasyarat

1. [Flutter 3.x](https://docs.flutter.dev/get-started/install) terpasang  
2. Desktop support aktif:

```bash
flutter config --enable-macos-desktop    # Mac
flutter config --enable-windows-desktop  # Windows
```

3. **Windows saja:** Visual Studio 2022 + workload *Desktop development with C++*  
4. Clone/repo LanCast, lalu dari root:

```bash
dart pub get
```

Opsional: set path Flutter di [`config/lancast.env`](../config/lancast.env):

```env
FLUTTER_BIN=/Applications/development/flutter/bin
# Windows contoh:
# FLUTTER_BIN=C:\src\flutter\bin
LANCAST_DEVICE=macos
# LANCAST_DEVICE=windows
```

---

## Cara menjalankan (development)

### macOS

**Paling mudah**

- Double-click `LanCast.command` di Finder, atau:

```bash
make run
```

**Manual 2 terminal**

```bash
# Terminal 1 — Arena / Viewer
cd apps/viewer
flutter run -d macos --dart-define=AUTO_ROOM=true

# Terminal 2 — Participant / Sender
cd apps/sender
flutter run -d macos
```

**Izin macOS**

- Participant: **Screen Recording** (+ Microphone jika share audio)  
- Local Network untuk discovery  

System Settings → Privacy & Security.

### Windows

**Paling mudah**

- Double-click `LanCast.bat`, atau di PowerShell dari root:

```powershell
$env:LANCAST_DEVICE="windows"
$env:LANCAST_AUTO_ROOM="true"
# Jalankan dua proses:
Start-Process powershell -ArgumentList "-NoExit","-Command","cd apps\viewer; flutter run -d windows --dart-define=AUTO_ROOM=true"
Start-Process powershell -ArgumentList "-NoExit","-Command","cd apps\sender; flutter run -d windows"
```

**Manual**

```bat
cd apps\viewer
flutter run -d windows --dart-define=AUTO_ROOM=true

cd apps\sender
flutter run -d windows
```

**Firewall:** izinkan UDP **17891** (discovery) dan TCP **17890** (signaling WebSocket).

---

## Alur pakai singkat

1. Buka **LanCast Arena** → Create Battle Room (atau AUTO_ROOM)  
2. **Share Join Link** (opsional) atau biarkan discovery UDP  
3. Buka **LanCast Participant** → Find Battle Room / Join via Link  
4. Arena: **Approve** join  
5. Participant: **Start Share**  
6. Arena: Lobby → Start Countdown → Arena HUD / Judge  

---

## Mengekspor aplikasi (release)

Hasil ada di folder `dist/`.

### macOS (jalankan di Mac)

```bash
make export
# atau
./scripts/export.sh macos
```

Output contoh:

```
dist/macos/LanCast-0.1.0-YYYYMMDD-HHMM/
  LanCast Arena.app
  LanCast Participant.app
  CARA_PAKAI.txt
dist/LanCast-macos-0.1.0-YYYYMMDD-HHMM.zip
```

Jika Gatekeeper memblokir app unsigned:

```bash
xattr -dr com.apple.quarantine "LanCast Arena.app"
xattr -dr com.apple.quarantine "LanCast Participant.app"
```

### Windows (jalankan di PC Windows)

```powershell
.\scripts\export.ps1
```

atau Git Bash:

```bash
./scripts/export.sh windows
```

Output contoh:

```
dist\windows\LanCast-0.1.0-YYYYMMDD-HHMM\
  LanCast Arena\          (lancast_viewer.exe + DLL)
  LanCast Participant\    (lancast_sender.exe + DLL)
  CARA_PAKAI.txt
dist\LanCast-windows-0.1.0-YYYYMMDD-HHMM.zip
```

> **Penting:** salin **seluruh folder** Release, jangan hanya file `.exe`.

> Build Windows tidak bisa dibuat dari Mac dengan Flutter desktop biasa — export Windows harus di mesin Windows.

---

## Troubleshooting

| Masalah | Cek |
|---------|-----|
| Room tidak muncul di Sender | Satu Wi-Fi/LAN? Firewall UDP 17891? Viewer room sudah dibuat? |
| Join gagal | WS URL di link = IP LAN Viewer; port 17890 terbuka |
| Tidak ada gambar share | macOS Screen Recording / Windows capture permission |
| `flutter` not found | PATH / `FLUTTER_BIN` di `config/lancast.env` |
| Windows build gagal | Install VS C++ Desktop workload, lalu `flutter doctor` |
