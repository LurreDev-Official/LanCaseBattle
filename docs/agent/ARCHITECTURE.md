# Architecture — Agent Reference

## System shape

```
Sender App ──(discovery)──► Viewer announces room (mDNS/UDP)
Sender App ──(WebSocket)──► Viewer Host Service (control plane)
Sender App ──(WebRTC)────► Viewer UI (media plane, 1-way video)
```

- **Viewer** = UI admin + **embedded host** (discovery publisher, WS signaling server, SQLite, token issuer).
- **Sender** = discovery client + WS client + screen capture + WebRTC publisher.
- No external backend.

## Responsibility matrix

| Concern | Owner package/app | Notes |
|---------|-------------------|-------|
| Domain models, enums, envelope | `lancast_core` | No Flutter UI deps |
| WS encode/decode + handlers | `lancast_signaling` | Depends on core |
| mDNS / UDP announce+scan | `lancast_discovery` | Platform quirks isolated here |
| PeerConnection helpers | `lancast_webrtc` | Wrap flutter_webrtc |
| Drift schema/repos | `lancast_storage` | Viewer-side persistence |
| Approval queue UI | `apps/viewer` | Uses storage + signaling |
| Sharing console UI | `apps/sender` | Uses secure storage for token |

## Suggested package graph

```
apps/viewer ──► signaling, discovery, webrtc, storage, core
apps/sender ──► signaling, discovery, webrtc, core
storage     ──► core
signaling   ──► core
discovery   ──► core
webrtc      ──► core
```

Jangan biarkan `viewer` import `sender` atau sebaliknya.

## Feature modules (per app)

```
lib/
├── main.dart
├── app.dart
├── core/                 # theme, router, constants, failures
├── features/
│   ├── discovery/
│   ├── room/
│   ├── approval/         # viewer only
│   ├── devices/          # viewer only
│   ├── streaming/
│   └── settings/
└── shared/widgets/
```

Layer per feature (jika dipakai):

- `presentation/` — screens, widgets, Riverpod providers
- `domain/` — use cases / pure logic (opsional di awal; wajib saat logic membesar)
- `data/` — repos, DTOs, platform adapters

## Runtime components (Viewer host)

Implement sebagai long-lived services (Riverpod `keepAlive` / plain singleton started from app bootstrap):

1. `DiscoveryAnnouncer` — publish `ROOM_ANNOUNCE` metadata
2. `SignalingServer` — accept WS; route events
3. `ApprovalService` — pending queue, approve/reject, timeouts
4. `TokenService` — issue, validate, revoke, TTL
5. `RoomSession` — device table, soft limit 6 streams
6. `RtcHub` — per-device PeerConnection on viewer side

Sender mirrors with clients: `DiscoveryScanner`, `SignalingClient`, `TokenStore`, `RtcPublisher`.

## State ownership

| State | Canonical location |
|-------|--------------------|
| Active room | Viewer memory + `rooms` table |
| Join requests | Viewer memory + `join_requests` |
| Device tokens | Viewer `devices`; Sender secure storage copy |
| Stream layout | Viewer UI state only |
| Capture on/off | Sender UI + `DEVICE_STATE` events |

## Ports & discovery (defaults — boleh diganti, dokumentasikan di code)

| Item | Default |
|------|---------|
| mDNS type | `_lancast._tcp` |
| Signaling WS port | `17890` |
| UDP broadcast fallback port | `17891` |
| Protocol version `v` | `1` |

## Security boundaries

- Signaling accepts connections from LAN; after join, require valid session/token for media signaling (`SIGNAL_*`).
- Reject `SIGNAL_OFFER` from devices not `APPROVED` / token valid.
- On revoke: close PC, mark `revoked=true`, push `ACCESS_REVOKED`.

## Bootstrap strategy

**Phase 0 OK:** satu Flutter app dengan mode `viewer|sender` di splash.

**Sebelum fase WebRTC multi-device:** pecah ke `apps/viewer` + `apps/sender` + packages agar permission & entrypoints bersih.

## Testing seams

- Pure: envelope parse, token TTL, PIN hash, state transitions
- Fake clock for request timeout (2 menit)
- Mock WS channel for approval flow without real LAN
- WebRTC: integration/manual on real devices; unit-test hanya signaling glue
