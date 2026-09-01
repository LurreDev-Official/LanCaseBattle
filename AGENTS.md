# Agent Instructions — LanCast

## Source of Truth
- Product/MVP: `skilll.md`
- Architecture: `docs/agent/ARCHITECTURE.md`
- Protocol: `docs/agent/PROTOCOL.md`
- Phased build: `docs/agent/BUILD_PLAN.md`
- Task checklist: `docs/agent/TASKS.md`
- Hard rules: `docs/agent/GUARDRAILS.md`

## Stack
Flutter 3.x · Dart 3.x · Riverpod · go_router · drift · flutter_webrtc · web_socket_channel  
Models: hand-written JSON in `lancast_core` (freezed optional later)

## Layout (target)
```
apps/viewer/          # Room admin + host (signaling + discovery + SQLite)
apps/sender/          # Discover, join, screen share
packages/lancast_core/
packages/lancast_discovery/   # UDP announce/scan (done)
packages/lancast_signaling/   # WS host/client (done)
packages/lancast_webrtc/      # screen share helpers
# drift storage deferred — in-memory + secure_storage for MVP
```

Bootstrap boleh single-app dulu; pecah monorepo sebelum WebRTC multi-stream.

## Commands
| Task | Command |
|------|---------|
| **One-shot run** | `make run` (Viewer+Sender, AUTO_ROOM) |
| Manual rooms | `make run-manual` |
| Open built apps | `make run-apps` |
| Stop | `make stop` |
| Config | `config/lancast.env` |
| Deps | `make deps` / `dart pub get` |
| Analyze | `make analyze` |
| Test | `make test` |
| Run viewer only | `cd apps/viewer && flutter run -d macos` |
| Run sender only | `cd apps/sender && flutter run -d macos` |

## Build Order
Ikuti `docs/agent/BUILD_PLAN.md` fase 0→7. Jangan lompat ke WebRTC sebelum approval + token jalan.

## Non-Negotiables
- LAN only — no cloud auth/API/telemetry
- No media track before `JOIN_APPROVED` + valid token
- Host/signaling lives in **Viewer** process
- PIN stored hashed; never plaintext in DB/logs
- One active room per Viewer (MVP)
- Screen share **Sender → Viewer** only (MVP)

## Conventions
- Feature-first under `lib/features/{discovery,room,approval,devices,streaming,settings}`
- Events: envelope `v/type/room_id/ts/payload` — see PROTOCOL
- Models: `lancast_core`; DB: drift (Fase 2+); state: Riverpod
- Identifiers & protocol `type` strings: English snake/`SCREAMING_SNAKE`
- UI copy: Indonesian OK

## Out of Scope (MVP)
Multi-room, audio, chat, remote pointer, iOS full capture, E2E crypto beyond local WS, trusted-only mode penuh

## Commit Attribution
AI commits MUST include:
```
Co-Authored-By: <agent model name> <noreply@example.com>
```
