# Build Plan — Agent Phases

Kerjakan **berurutan**. Jangan mulai fase N+1 jika DoD fase N belum hijau.

> Status repo: Fase 0–7 MVP sudah diimplementasi. Drift persistence (T2.5) dan verifikasi manual demo (T7.4) tetap opsional/manual.

Sumber produk: `skilll.md`. Detail task: `TASKS.md`.

---

## Fase 0 — Skeleton

**Goal:** app(s) jalan, routing, Riverpod, theme kosong.

- `flutter create` viewer (+ sender atau single-app dual-mode)
- Dependensi inti: riverpod, go_router, freezed, json_serializable, logger
- Struktur `lib/core` + `lib/features/*` kosong
- Splash pilih mode **hanya jika** single-app

**DoD:** `flutter run` menampilkan shell Viewer & Sender (atau mode switch) tanpa crash.

---

## Fase 1 — Core models & envelope

**Goal:** `lancast_core` (atau `lib/core/protocol`) dengan freezed models.

- Enums: roles, security_mode, device/request status
- Envelope + typed payloads untuk semua event MVP
- Unit test: serialize/deserialize round-trip

**DoD:** test envelope hijau; tidak ada string `type` tersebar magic di UI.

---

## Fase 2 — Room create + discovery

**Goal:** Viewer buat room; Sender melihat daftar room LAN.

- Viewer: Create Room form → start `DiscoveryAnnouncer` + `SignalingServer` listen
- Persist room row (drift) — boleh in-memory dulu, drift wajib sebelum fase 4 selesai
- Sender: scan → Room List UI
- Fallback UDP jika mDNS gagal di platform dev

**DoD:** dua device/simulator satu LAN (atau localhost loopback test) — room muncul di Sender.

---

## Fase 3 — Join request + Approval UI

**Goal:** controlled access tanpa media.

- Sender: Request Join → `WAITING_APPROVAL`
- Viewer: Approval Queue overlay/list — Approve / Reject
- Events: `JOIN_REQUEST` / `JOIN_APPROVED` / `JOIN_REJECTED`
- Timeout 120s → expired

**DoD:** approve/reject terlihat kedua sisi; **belum** ada WebRTC.

---

## Fase 4 — Token issue / store / revoke

**Goal:** sesi terpercaya.

- `TokenService` issue opaque token + expiry
- Viewer persist device; Sender secure storage
- Reconnect dengan `resume_token` skip queue jika valid
- Device Manager: Remove → `ACCESS_REVOKED`
- PIN hash jika PIN diaktifkan

**DoD:** revoke memutus sesi; reconnect token valid tanpa approve ulang.

---

## Fase 5 — WebRTC satu stream

**Goal:** satu Sender → satu tile di Viewer.

- Setelah approved: exchange `SIGNAL_*`
- Sender: getDisplayMedia / platform capture
- Viewer: render remote track
- Gate: tolak signaling jika belum approved

**DoD:** layar Sender terlihat di Viewer; reject path tetap tanpa media.

---

## Fase 6 — Multi-stream grid + device manager

**Goal:** hingga soft-limit 6.

- Layout 1×1 / 2×2 / auto
- `DEVICE_STATE` idle/streaming/paused
- Quality presets (720p30 default)
- Label device + remove dari dashboard

**DoD:** ≥2 sender (atau mock PC kedua) tampil di grid; remove salah satu tidak rusak yang lain.

---

## Fase 7 — Hardening

**Goal:** demo-ready.

- Heartbeat + stale disconnect
- Room close → `ROOM_CLOSED`
- Error surfaces (rejected/revoked/timeout)
- Offline-cloud check (matikan internet, LAN tetap)
- Logging aman (jangan log PIN/token penuh)

**DoD:** semua checkbox §20 di `skilll.md` tercentang.

---

## Explicit defer (jangan kerjakan di MVP)

- Chat, remote cursor
- Multi-room paralel
- iOS broadcast extension
- E2E encryption custom
- `trusted_device_only` mode penuh (reconnect token sudah cukup untuk MVP)

---

## Agent session recipe

```
1. Baca AGENTS.md + fase aktif di dokumen ini
2. Ambil task IDs terkait di TASKS.md
3. Implement minimal diff
4. Jalankan dart analyze / flutter test yang relevan
5. Tandai task [x] di TASKS.md hanya jika acceptance lulus
6. Stop dan laporkan jika butuh keputusan produk di luar skilll.md
```
