# LanCast

Open-source local-network multi-device screen sharing (Flutter) — **LanCast Arena**.

Controlled room access: senders request join → room admin approves → WebRTC screen share on LAN.

## Petunjuk cepat (Mac & Windows)

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
