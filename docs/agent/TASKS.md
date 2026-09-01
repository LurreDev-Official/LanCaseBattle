# Tasks — Atomic Checklist for Agents

Centang hanya jika acceptance lulus. ID stabil — jangan rename.

## Fase 0 — Skeleton

- [x] `T0.1` Scaffold Flutter app(s) org `com.lancast`
- [x] `T0.2` Add Riverpod + go_router + base `MaterialApp.router`
- [x] `T0.3` Folder features kosong + theme tokens dasar

## Fase 1 — Core / Protocol

- [x] `T1.1` Envelope model + JSON round-trip (`packages/lancast_core`)
- [x] `T1.2` Enums: `SecurityMode`, `SenderStatus`, `JoinRequestStatus`, `DeviceStreamState`
- [x] `T1.3` Payload models untuk JOIN_* / ACCESS_REVOKED / DEVICE_* / SIGNAL_* / HEARTBEAT / ROOM_*
- [x] `T1.4` Central `EventType` constants — no raw strings di UI

## Fase 2 — Room + Discovery

- [x] `T2.1` Create Room screen (name, security mode, optional PIN)
- [x] `T2.2` Generate `room_id` stabil + start host services
- [x] `T2.3` `ROOM_ANNOUNCE` via UDP broadcast (+ loopback for same-host)
- [x] `T2.4` Sender Room List dari scan
- [ ] `T2.5` Persist `rooms` (drift) — deferred; in-memory room session OK for MVP demo

## Fase 3 — Approval

- [x] `T3.1` Sender kirim `JOIN_REQUEST` + UI waiting
- [x] `T3.2` Viewer approval queue UI
- [x] `T3.3` Approve → `JOIN_APPROVED`
- [x] `T3.4` Reject → `JOIN_REJECTED` + reason
- [x] `T3.5` Timeout 120s → expired

## Fase 4 — Token

- [x] `T4.1` Issue opaque token + `expires_at` (device vault di Viewer)
- [x] `T4.2` Sender simpan token di secure storage
- [x] `T4.3` Resume join dengan `resume_token`
- [x] `T4.4` Remove device → `ACCESS_REVOKED` + close session
- [x] `T4.5` PIN hash (SHA-256) — plaintext tidak disimpan di `ActiveRoom`

## Fase 5 — WebRTC single

- [x] `T5.1` Gate: `SIGNAL_*` only if approved+token
- [x] `T5.2` Offer/answer/ICE exchange
- [x] `T5.3` Sender screen capture start/stop (`getDisplayMedia`)
- [x] `T5.4` Viewer tile renderer (`RTCVideoView`)

## Fase 6 — Multi + UX

- [x] `T6.1` Support ≥2 peer connections + soft limit 6
- [x] `T6.2` Grid layouts 1×1 / 2×2 / auto
- [x] `T6.3` `DEVICE_STATE` idle/streaming/paused + UI badges
- [x] `T6.4` Quality preset 720p30 / 1080p30
- [x] `T6.5` Device manager list + remove

## Fase 7 — Hardening

- [x] `T7.1` Heartbeat + stale disconnect
- [x] `T7.2` Room close → `ROOM_CLOSED` ke semua sender
- [x] `T7.3` Tidak log PIN/token penuh (`redactToken`)
- [ ] `T7.4` Demo checklist `skilll.md` §20 — verifikasi manual di perangkat

## Definition of done (global)

Demo LAN: create room → request → approve → stream → revoke → reconnect token → reject path → no internet masih jalan.
