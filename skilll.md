# LanCast

**Open Source · Local Network · Multi-Device Screen Sharing**

Spesifikasi produk siap implementasi Flutter. Semua komunikasi berjalan di LAN; tidak ada akun cloud.

---

## 1. Ringkasan Produk

LanCast memungkinkan beberapa device berbagi layar ke satu Viewer di jaringan lokal (kelas, kantor, training, control room).

Prinsip inti:

- Akses room dikontrol (default: approval admin)
- Tidak ada stream sebelum device disetujui
- Token akses dapat dicabut kapan saja
- 100% lokal (discovery, signaling, media)

---

## 2. Target Platform (Flutter)

| Role app | Platform prioritas MVP | Catatan |
|----------|------------------------|---------|
| **Viewer / Room Admin** | Windows, macOS, Linux | Desktop-first; tampilkan banyak stream |
| **Sender** | Windows, macOS, Android | Capture + kirim layar |
| Opsional lanjut | iOS, Web | iOS: batasan capture; Web: viewer ringan |

Satu codebase Flutter dengan flavor/role:

- `lancast_viewer` — admin + display
- `lancast_sender` — request join + screen share

Boleh digabung dalam satu app dengan mode pemilihan di splash, selama permission & UI dipisah jelas.

---

## 3. Role System

### 3.1 Room Owner (Administrator)

Device yang menjalankan Viewer dan membuat room.

| Boleh | Tidak |
|-------|-------|
| Buat / tutup room | — |
| Atur PIN & security mode | — |
| Approve / reject join request | — |
| Remove device & revoke token | — |
| Atur layout multi-screen | — |
| Atur kualitas stream (resolusi/bitrate/FPS) | — |

Status UI: `ROOM ADMIN`

### 3.2 Approved Sender

Device yang sudah di-approve.

| Boleh | Tidak |
|-------|-------|
| Share / pause / stop screen | Masuk tanpa token valid |
| Ubah display name | Approve device lain |
| Leave room | Lihat stream device lain (MVP) |

Status: `APPROVED` → `CONNECTED` → `STREAMING` | `IDLE`

### 3.3 Guest Device

Belum punya izin.

| Boleh | Tidak |
|-------|-------|
| Discover room di LAN | Streaming |
| Kirim join request | Melihat layar lain |
| Batalkan request | Akses isi room |

Status: `DISCOVERING` | `WAITING_APPROVAL` | `REJECTED`

---

## 4. Security Mode

| Mode | Perilaku join | Default |
|------|---------------|---------|
| `approval_required` | Request → admin approve/reject | Ya |
| `pin_required` | Masuk dengan PIN room (tanpa antrian approval) | Tidak |
| `trusted_device_only` | Hanya device dengan token valid yang pernah di-approve | Tidak |

Kombinasi yang didukung MVP:

- Approval saja
- PIN + Approval (PIN dulu, lalu tetap perlu approve)
- Trusted auto-join (reconnect dengan token belum expired & belum di-revoke)

---

## 5. Room Lifecycle

```text
[Admin] Create Room
    → Room aktif di LAN (mDNS / UDP broadcast)
    → Terima JOIN_REQUEST
    → Approve / Reject
    → Signaling WebRTC
    → Streams tampil di Viewer
    → (opsional) Remove / Close Room
```

### Data room (contoh)

```text
name:           TRAINING ROOM A
room_id:        TRAIN-A001
security_pin:   839201          # opsional, hashed di storage
security_mode:  approval_required
owner_device:   Main-Display-PC
created_at:     ISO-8601
```

---

## 6. Join Flow (Approval Required)

### Step 1 — Discovery

Sender scan LAN.

```text
Available Rooms
────────────────
TRAINING ROOM A
Owner: Main-PC
Mode:  Approval Required
Status: Open
```

### Step 2 — Request Join

Payload minimal:

```json
{
  "type": "JOIN_REQUEST",
  "request_id": "uuid",
  "room_id": "TRAIN-A001",
  "device": {
    "device_id": "uuid-stable",
    "name": "Laptop-Andi",
    "username": "Andi",
    "os": "windows",
    "os_version": "11",
    "ip": "192.168.1.45",
    "app_version": "0.1.0"
  },
  "pin": null,
  "timestamp": "2026-08-11T10:15:20+07:00"
}
```

### Step 3 — Admin Notification

Overlay / panel di Viewer:

```text
New Join Request
Device: Laptop-Andi
OS:     Windows 11
IP:     192.168.1.45
Time:   10:15:20

[Approve]  [Reject]
```

### Step 4 — Keputusan

**Approve** → kirim token + izinkan signaling.

```json
{
  "type": "JOIN_APPROVED",
  "request_id": "uuid",
  "device_id": "uuid-stable",
  "room_id": "TRAIN-A001",
  "token": {
    "value": "opaque-token",
    "permission": "screen_share",
    "expires_at": "2026-08-12T10:15:20+07:00"
  }
}
```

**Reject**

```json
{
  "type": "JOIN_REJECTED",
  "request_id": "uuid",
  "device_id": "uuid-stable",
  "reason": "Admin denied"
}
```

### Transisi status Sender

```text
DISCOVERING → REQUESTING → WAITING_APPROVAL
    → APPROVED → CONNECTING → CONNECTED
    → STREAMING | IDLE
```

Reject / timeout / revoke → `REJECTED` | `DISCONNECTED`

---

## 7. Device Permission Token

Setiap device yang di-approve mendapat token lokal.

```json
{
  "device_id": "LAPTOP-001",
  "room_id": "TRAIN-A001",
  "permission": "screen_share",
  "approved": true,
  "token": "opaque-token",
  "issued_at": "2026-08-11T10:15:20+07:00",
  "expires_at": "2026-08-12T10:15:20+07:00",
  "revoked": false
}
```

Aturan:

- Reconnect dalam masa berlaku: tidak perlu approve ulang (kecuali mode memaksa)
- `ACCESS_REVOKED` atau expired → putus stream + hapus sesi
- Token disimpan lokal (Viewer: SQLite; Sender: secure storage)

Revoke:

```json
{
  "type": "ACCESS_REVOKED",
  "device_id": "LAPTOP-001",
  "room_id": "TRAIN-A001",
  "reason": "Removed by admin"
}
```

---

## 8. Admin Device Management

```text
Connected Devices
─────────────────
✓ Laptop-Andi   Windows   STREAMING
✓ Laptop-Budi   macOS     IDLE

[Remove Access]
```

Remove → `TOKEN REVOKED` → Sender `Disconnected`.

---

## 9. Arsitektur Teknis (Flutter)

```text
                    LAN
         ┌──────────┴──────────┐
         │                     │
   Sender App            Viewer App
   (Flutter)             (Flutter)
         │                     │
    Screen Capture        Room Admin UI
    Join Client           Approval Queue
         │                     │
         └────────┬────────────┘
                  │
         LanCast Host Service
         (jalan di proses Viewer)
         ├── Discovery (mDNS / UDP)
         ├── Signaling (WebSocket)
         ├── Token & Approval
         ├── Room state
         └── SQLite
                  │
              WebRTC P2P
           (media: screen tracks)
```

Catatan desain:

- **Host/Signaling server tertanam di Viewer** (MVP). Tidak ada server cloud.
- Media: **WebRTC** (flutter_webrtc).
- Control plane: WebSocket JSON events.
- Discovery: mDNS (`_lancast._tcp`) + fallback UDP broadcast.

---

## 10. Tech Stack Flutter

| Area | Pilihan |
|------|---------|
| Framework | Flutter 3.x · Dart 3.x |
| State | Riverpod |
| Routing | go_router |
| Models | freezed + json_serializable |
| Lokal DB (Viewer) | drift (SQLite) |
| Secure storage (Sender token) | flutter_secure_storage |
| Realtime | web_socket_channel |
| WebRTC | flutter_webrtc |
| Discovery | multicast_dns / raw UDP (platform channel bila perlu) |
| Screen capture | desktop: `flutter_webrtc` / platform APIs; Android: MediaProjection |
| Logging | talker / logger |
| Lint | very_good_analysis (opsional) |

---

## 11. Struktur Folder (usulan)

```text
lancast/
├── apps/
│   ├── viewer/                 # Room admin + display
│   └── sender/                 # Join + share
├── packages/
│   ├── lancast_core/           # models, events, enums
│   ├── lancast_signaling/      # WS protocol + handlers
│   ├── lancast_discovery/      # mDNS / UDP
│   ├── lancast_webrtc/         # peer connection helpers
│   └── lancast_storage/        # drift schema + repos
├── skilll.md                   # spesifikasi ini
└── README.md
```

Jika monorepo belum dipakai di awal, mulai single app + `lib/features/...`, lalu pecah package.

Feature modules (minimal):

```text
lib/
├── core/           # theme, router, constants, errors
├── features/
│   ├── discovery/
│   ├── room/
│   ├── approval/
│   ├── devices/
│   ├── streaming/
│   └── settings/
└── shared/
```

---

## 12. Skema Lokal (SQLite / Drift)

### rooms

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | room_id |
| name | text | |
| owner_device_id | text | |
| security_mode | text | enum |
| pin_hash | text nullable | never store plain PIN |
| created_at | datetime | |
| is_active | bool | |

### devices

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | device_id |
| room_id | text FK | |
| name | text | |
| username | text nullable | |
| ip | text | |
| os | text | |
| status | text | enum |
| approved | bool | |
| token | text nullable | |
| token_expires_at | datetime nullable | |
| revoked | bool | default false |
| last_seen | datetime | |

### join_requests

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | request_id |
| room_id | text | |
| device_id | text | |
| payload_json | text | |
| status | text | pending/approved/rejected/expired |
| created_at | datetime | |
| resolved_at | datetime nullable | |

---

## 13. Protocol Events (control plane)

| type | Arah | Keterangan |
|------|------|------------|
| `ROOM_ANNOUNCE` | Viewer → LAN | discovery metadata |
| `JOIN_REQUEST` | Sender → Viewer | minta masuk |
| `JOIN_APPROVED` | Viewer → Sender | + token |
| `JOIN_REJECTED` | Viewer → Sender | + reason |
| `ACCESS_REVOKED` | Viewer → Sender | putus akses |
| `DEVICE_LEFT` | Sender → Viewer | leave sukarela |
| `DEVICE_STATE` | Sender → Viewer | idle/streaming/paused |
| `SIGNAL_OFFER` | Peer | WebRTC |
| `SIGNAL_ANSWER` | Peer | WebRTC |
| `SIGNAL_ICE` | Peer | WebRTC |
| `ROOM_CLOSED` | Viewer → Sender | room ditutup |
| `HEARTBEAT` | dua arah | liveness |

Semua event membungkus envelope:

```json
{
  "v": 1,
  "type": "JOIN_REQUEST",
  "room_id": "TRAIN-A001",
  "ts": "2026-08-11T10:15:20+07:00",
  "payload": {}
}
```

---

## 14. Layar Flutter (MVP)

### Viewer

1. **Home** — Create Room / Resume last room  
2. **Create Room** — nama, mode keamanan, PIN opsional  
3. **Room Dashboard** — grid stream + status device  
4. **Approval Queue** — list request pending (badge)  
5. **Device Manager** — remove / rename label  
6. **Layout Settings** — 1×1, 2×2, auto  
7. **Stream Quality** — 720p/1080p, FPS, bitrate  

### Sender

1. **Home** — Scan rooms  
2. **Room List** — hasil discovery  
3. **Request Join** — konfirmasi nama device (+ PIN jika perlu)  
4. **Waiting Approval** — status + cancel  
5. **Sharing Console** — Start / Pause / Stop / Leave  
6. **Rejected / Revoked** — pesan jelas + kembali ke scan  

---

## 15. UX Target (alur singkat)

**Sender**

1. Buka LanCast Sender  
2. Pilih room  
3. Request Join  
4. Tunggu approval  
5. Start Share Screen  

**Admin**

1. Jalankan Viewer  
2. Buat room  
3. Approve request  
4. Atur layout  
5. Tampilkan semua screen  

---

## 16. Non-Functional Requirements

| Aspek | Target MVP |
|-------|------------|
| Latency kontrol | < 200 ms di LAN tipikal |
| Video | 720p30 default; 1080p opsional |
| Device per room | hingga 6 stream aktif (soft limit) |
| Offline cloud | wajib (tanpa internet) |
| Privacy | tidak ada telemetry wajib |
| Token TTL default | 24 jam (konfigurabel) |
| Request timeout | 2 menit tanpa respons admin → expired |

---

## 17. Izin Platform

| Platform | Izin |
|----------|------|
| Android | Internet, Nearby/Wi‑Fi, MediaProjection (screen capture), notifikasi |
| Windows / macOS / Linux | Screen recording / accessibility sesuai OS; firewall lokal |
| iOS (lanjutan) | Broadcast Upload Extension bila full screen share |

---

## 18. Prinsip Keamanan

1. Tidak ada device masuk room tanpa lolos mode keamanan aktif  
2. Tidak ada track media sebelum `JOIN_APPROVED` + token valid  
3. Token dapat di-revoke; revoke langsung putus peer connection  
4. PIN disimpan sebagai hash, bukan plaintext  
5. Binding soft ke `device_id` stabil + room_id  
6. Semua traffic control/media hanya di LAN  
7. Tolak event dari IP/device yang tidak punya sesi valid (setelah join)

---

## 19. Batasan MVP (agar bisa di-build dulu)

**Masuk MVP**

- Satu room aktif per Viewer  
- Mode `approval_required` (+ PIN opsional)  
- Approve / reject / revoke  
- WebRTC screen share 1 arah (Sender → Viewer)  
- Audio I/O settings (mic/speaker select, mute, test) + optional mic share  
- Grid layout dasar  
- SQLite device + token  

**Di luar MVP (fase 2)**

- Multi-room paralel  
- Chat / pointer remote  
- Trusted-device-only sebagai mode penuh  
- Enkripsi signaling end-to-end di atas WSS lokal  
- Viewer mobile  
- Rekaman sesi  

---

## 20. Definition of Done (siap demo)

- [ ] Viewer membuat room dan ter-discover di LAN  
- [ ] Sender muncul sebagai `WAITING_APPROVAL`  
- [ ] Approve → token tersimpan → WebRTC connected  
- [ ] Reject → sender mendapat alasan, tidak ada media  
- [ ] Remove device → stream berhenti, token revoked  
- [ ] Reconnect dengan token valid tanpa approve ulang  
- [ ] Tanpa internet (airplane mode router tetap LAN) alur masih jalan  

---

## 21. Urutan Implementasi yang Disarankan

1. Monorepo/app skeleton + Riverpod + router  
2. Models/events (`lancast_core`) + envelope protocol  
3. Discovery + Create Room  
4. Join request + Approval UI  
5. Token issue/store/revoke  
6. WebRTC signaling + satu stream  
7. Multi-stream grid + device manager  
8. Hardening (timeout, heartbeat, reconnect)  

---

Dokumen ini adalah sumber kebenaran produk sebelum scaffolding Flutter. Implementasi harus mengikuti role, security mode, event protocol, dan batasan MVP di atas.

**Untuk AI coding agent:** mulai dari [`AGENTS.md`](AGENTS.md) dan playbook di [`docs/agent/`](docs/agent/).
