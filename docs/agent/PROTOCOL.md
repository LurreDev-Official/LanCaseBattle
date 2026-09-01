# Protocol — Agent Reference

Wire format & state machines. Product narrative: `skilll.md`. Jika bentrok, **dokumen ini menang untuk JSON/type string**.

## Envelope (wajib semua control events)

```json
{
  "v": 1,
  "type": "JOIN_REQUEST",
  "room_id": "TRAIN-A001",
  "ts": "2026-08-11T10:15:20+07:00",
  "payload": {}
}
```

| Field | Rule |
|-------|------|
| `v` | int; reject jika unsupported |
| `type` | `SCREAMING_SNAKE` dari tabel di bawah |
| `room_id` | string; wajib kecuali pre-room announce scan-only |
| `ts` | ISO-8601 with offset |
| `payload` | object; schema per `type` |

Unknown `type`: log + ignore (jangan crash).

## Event catalog

### ROOM_ANNOUNCE (Viewer → LAN / discovery)

```json
{
  "room_id": "TRAIN-A001",
  "name": "TRAINING ROOM A",
  "owner_name": "Main-PC",
  "security_mode": "approval_required",
  "pin_required": true,
  "ws_url": "ws://192.168.1.10:17890",
  "status": "open",
  "protocol_v": 1
}
```

`security_mode`: `approval_required` | `pin_required` | `trusted_device_only`

### JOIN_REQUEST (Sender → Viewer)

```json
{
  "request_id": "uuid",
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
  "resume_token": null
}
```

- `resume_token`: jika reconnect dengan token lama.
- Viewer: jika token valid & tidak revoked → auto `JOIN_APPROVED` tanpa antrian (MVP reconnect).

### JOIN_APPROVED (Viewer → Sender)

```json
{
  "request_id": "uuid",
  "device_id": "uuid-stable",
  "token": {
    "value": "opaque-token",
    "permission": "screen_share",
    "expires_at": "2026-08-12T10:15:20+07:00"
  }
}
```

### JOIN_REJECTED (Viewer → Sender)

```json
{
  "request_id": "uuid",
  "device_id": "uuid-stable",
  "reason": "Admin denied"
}
```

### ACCESS_REVOKED (Viewer → Sender)

```json
{
  "device_id": "uuid-stable",
  "reason": "Removed by admin"
}
```

### DEVICE_LEFT (Sender → Viewer)

```json
{
  "device_id": "uuid-stable",
  "reason": "user_leave"
}
```

### DEVICE_STATE (Sender → Viewer)

```json
{
  "device_id": "uuid-stable",
  "state": "streaming"
}
```

`state`: `idle` | `streaming` | `paused`

### SIGNAL_OFFER / SIGNAL_ANSWER / SIGNAL_ICE

```json
{
  "device_id": "uuid-stable",
  "sdp": "...",
  "type": "offer"
}
```

ICE:

```json
{
  "device_id": "uuid-stable",
  "candidate": { }
}
```

Hanya setelah approved + token valid.

### ROOM_CLOSED (Viewer → Sender)

```json
{
  "reason": "admin_closed"
}
```

### HEARTBEAT (dua arah)

```json
{
  "device_id": "uuid-stable",
  "seq": 1
}
```

Interval saran: 10s. Miss 3× → treat disconnect.

## Sender status machine

```
DISCOVERING
  → REQUESTING
  → WAITING_APPROVAL
  → APPROVED
  → CONNECTING
  → CONNECTED
  → STREAMING | IDLE

WAITING_APPROVAL → REJECTED (reject/timeout)
ANY_JOINED → DISCONNECTED (revoke/room_closed/network)
```

Map ke UI routes Sender sesuai status.

## Viewer request status

`pending` → `approved` | `rejected` | `expired`

- Timeout default: **120s** tanpa aksi admin → `expired` + optional notify sender (`JOIN_REJECTED` reason `timeout`).

## Token rules

| Rule | Value |
|------|-------|
| TTL default | 24h |
| Permission MVP | `screen_share` only |
| Storage Viewer | `devices.token` + `token_expires_at` + `revoked` |
| Storage Sender | secure storage keyed by `room_id` |
| Reconnect | valid token + same `device_id` + `room_id` → skip approval queue |
| Revoke | set `revoked=true`, close WS media session + PeerConnection |

## AuthZ cheatsheet

| Event from Sender | Allowed when |
|-------------------|--------------|
| `JOIN_REQUEST` | always (rate-limit later) |
| `DEVICE_STATE` / `DEVICE_LEFT` | session established |
| `SIGNAL_*` | approved && token valid && !revoked |
| anything else | ignore |

## Error payload (opsional, konsisten)

Jika perlu kirim error generik:

```json
{
  "code": "UNAUTHORIZED",
  "message": "token revoked"
}
```

`type`: `ERROR` (fase hardening; MVP boleh tutup socket saja).
