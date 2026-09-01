# LanCast Cloud — Draft Skill / Product Spec

**Status:** DRAFT (belum diimplementasi)  
**Parent product:** [`skilll.md`](skilll.md) (LanCast LAN) + fitur Arena yang sudah ada  
**Audience:** Product + AI coding agents  
**Bahasa:** Indonesia (identifier & protocol `type` tetap English)

---

## 0. Cara pakai dokumen ini (untuk agent)

Dokumen ini adalah **skill produk** untuk membangun **LanCast Cloud**: evolusi LanCast Arena ke mode online (internet / hybrid web), tanpa membuang fondasi LAN.

| Jika… | Lakukan… |
|--------|----------|
| Masih MVP LAN | Ikuti `skilll.md` + `AGENTS.md` + `docs/agent/*` |
| Mulai Cloud / Web | Ikuti dokumen ini; jangan pecahkan jaminan LAN-only di branch MVP |
| Bentrok protocol | Cloud menambah transport & auth; envelope `v/type/room_id/ts/payload` tetap |
| Scope creep | Lihat §19 Batasan Cloud MVP |

**Non-negotiable warisan dari LAN:**

- Tidak ada media track sebelum `JOIN_APPROVED` + token valid  
- PIN di-hash; token bisa revoke → peer putus  
- Screen share arah utama: **Sender → Viewer/Arena**  
- UI copy boleh Indonesia; wire protocol English  

---

## 1. Ringkasan produk

**LanCast Cloud** = platform screen-sharing + **battle arena** untuk kompetisi programming / cyber bug hunter yang bisa jalan:

1. **LAN** (mode existing) — offline, discovery UDP, signaling di Viewer  
2. **Cloud relay** — room online via server signaling + STUN/TURN  
3. **Web Judge / Web Lobby** — monitor arena dari browser  
4. **Desktop Participant** — capture layar penuh tetap di app Sender  

Posisi: *Cyber Esports Battle Command Center* yang bisa dipakai di lab lokal **atau** turnamen remote.

### 1.1 Fitur yang sudah ada di LAN (harus di-port / di-mirror)

| Area | Fitur existing | Cloud harus… |
|------|----------------|--------------|
| Arena HUD | Grid 2×2, team card (nama, logo, live, score, tool, network ms) | Sama UX; stream dari remote peers |
| Timer | Waiting / Countdown / Running / Warning / Finished / Paused | State sync ke semua client via server |
| Create Battle | 4 team slots, duration, countdown, category Programming / Bug Hunter | Persist di cloud room |
| Lobby | Waiting room + slot fill | Realtime presence |
| Approval | Popup Approve/Reject | Sama; host = Judge cloud session |
| Judge | Pause/end, scoring +/− | Auth role `judge` |
| Participant | Request join, waiting, sharing console | Desktop app + opsional browser share terbatas |
| Audio | Mic/speaker select, mute, test, optional mic share | WebRTC audio tracks + device settings |
| Join link | `lancast://join?...` share/copy | + `https://join.lancast.app/r/...` deep link |

---

## 2. Goals & non-goals

### Goals (Cloud MVP)

- Buat battle room dari web atau desktop Arena  
- Bagikan **link HTTPS** ke peserta (lintas jaringan)  
- Judge approve peserta; 4 stream tampil di Arena HUD  
- Timer & score sync realtime  
- Audio opsional (mic share)  
- Fallback: room masih bisa mode LAN-only tanpa cloud account  

### Non-goals (v1)

- E2EE penuh media (cukup DTLS WebRTC + TLS signaling)  
- Mobile full screen-capture iOS setara desktop  
- Multi-arena puluhan room paralel per org (batas kecil dulu)  
- Monetisasi / marketplace  
- AI auto-scoring kode  

---

## 3. Role system (Cloud)

| Role | App | Boleh |
|------|-----|-------|
| **Org Admin** | Web console | Buat org, invite judge, batasi kuota room |
| **Judge / Arena Host** | Web Judge + Desktop Arena | Create battle, approve, timer, score, share link, mute all |
| **Participant / Sender** | Desktop Sender (prioritas), Web Sender (terbatas) | Join via link, share screen (+ mic), mute self |
| **Spectator** (opsional fase 2) | Web | Lihat HUD + streams read-only |

Status participant (tetap):  
`DISCOVERING` | `WAITING_APPROVAL` | `REJECTED` | `APPROVED` | `CONNECTED` | `STREAMING` | `IDLE`

Battle phase (tetap):  
`waiting` | `countdown` | `running` | `warning` | `finished` | `paused`

---

## 4. Arsitektur Cloud (target)

```text
┌─────────────────┐     WSS      ┌──────────────────────┐
│ Judge Web /     │◄────────────►│ Cloud Signaling      │
│ Arena Desktop   │              │ + Room Service       │
└────────┬────────┘              │ + Auth (session)     │
         │ WebRTC                └──────────┬───────────┘
         │ (mesh atau SFU later)            │
┌────────▼────────┐                         │ STUN/TURN
│ Participants    │◄────────────────────────┘
│ (Desktop/Web)   │
└─────────────────┘
```

### 4.1 Komponen

| Komponen | Tanggung jawab |
|----------|----------------|
| **Auth service** | Login judge (email/magic link/OIDC opsional); participant bisa *anonymous join* dengan display name |
| **Room service** | CRUD battle room, team slots, category, duration, PIN hash |
| **Signaling gateway** | WebSocket envelope sama seperti LAN (`v/type/room_id/ts/payload`) |
| **STUN/TURN** | Coturn self-host atau provider; config per room |
| **Presence / battle sync** | Phase timer, scores, DEVICE_STATE |
| **Join link service** | Short URL → room metadata + ws/wss endpoint |
| **Optional SFU** (fase 2) | Jika 4+ HD streams memberatkan mesh |

### 4.2 Mode transport

| Mode | Discovery | Signaling | Media |
|------|-----------|-----------|-------|
| `lan` | UDP `ROOM_ANNOUNCE` | WS di Viewer process | Host candidates LAN |
| `cloud` | HTTPS join link | WSS cloud | STUN/TURN |
| `hybrid` | UDP + cloud register | Prefer cloud jika online | ICE dual |

Cloud MVP fokus **`cloud` + keep `lan` intact**.

---

## 5. Join link (Cloud)

### 5.1 Legacy (LAN) — tetap didukung

```text
lancast://join?room_id=…&ws_url=ws://192.168.x.x:17890&…
```

### 5.2 Cloud link

```text
https://join.lancast.app/r/{room_code}
```

Resolve response (contoh):

```json
{
  "room_id": "ARENA-42",
  "name": "OPEN CUP",
  "category": "cyber_bug_hunter",
  "signaling_wss": "wss://sig.lancast.app/rooms/ARENA-42",
  "ice_servers": [
    { "urls": ["stun:stun.lancast.app:3478"] },
    { "urls": ["turn:turn.lancast.app:3478"], "username": "…", "credential": "…" }
  ],
  "security_mode": "approval_required",
  "pin_required": false,
  "protocol_v": 1
}
```

Sender Cloud: buka link → isi nama → `JOIN_REQUEST` via WSS → waiting → approve → share.

---

## 6. Protocol

### 6.1 Envelope (tidak berubah)

```json
{
  "v": 1,
  "type": "JOIN_REQUEST",
  "room_id": "ARENA-42",
  "ts": "2026-08-12T00:00:00+07:00",
  "payload": {}
}
```

### 6.2 Event existing (wajib tetap)

`ROOM_ANNOUNCE`, `JOIN_REQUEST`, `JOIN_APPROVED`, `JOIN_REJECTED`, `TOKEN_REVOKE`, `SIGNAL_OFFER`, `SIGNAL_ANSWER`, `SIGNAL_ICE`, `DEVICE_STATE`, `HEARTBEAT`, `ROOM_CLOSED`

### 6.3 Event baru Cloud / Arena sync

| type | Arah | Payload ringkas |
|------|------|-----------------|
| `BATTLE_CONFIG` | Host → all | name, category, duration, countdown, teams[] |
| `BATTLE_PHASE` | Host → all | phase, remaining_ms, server_ts |
| `BATTLE_SCORE` | Host → all | slot_index, score |
| `TEAM_SLOT_UPDATE` | Host → all | slot, player, presence, language_or_tool |
| `ICE_SERVERS` | Server → client | iceServers[] (jangan log credential penuh) |
| `ROOM_SUBSCRIBE` | Client → server | room_id, role, resume_token? |

Detail JSON final: perlu ADR di `docs/agent/PROTOCOL_CLOUD.md` saat implementasi.

---

## 7. UI/UX yang harus dibawa ke Cloud

### 7.1 Arena Battle HUD (Judge / big screen)

- Dark cyber-esports + SOC aesthetic (cyan/lime, Orbitron/Rajdhani)  
- Fullscreen **2×2** responsive (tidak boleh potong slot 3–4)  
- Central timer HUD  
- Status header: brand, battle name, category, phase, room code, share link  
- Team card: avatar, online/live, score, tool/lang, latency  

### 7.2 Create Battle Room

- 4 team name slots  
- Duration + countdown sliders  
- Category: `PROGRAMMING` | `CYBER BUG HUNTER`  
- Output: cloud room + shareable HTTPS link  

### 7.3 Lobby

- 4 slots presence  
- Join approval popup (Approve / Reject)  
- Start Countdown  

### 7.4 Judge Dashboard

- Timer controls: Countdown / Start / Pause / Resume / End / Reset Lobby  
- Scoring per team  
- Monitor peers / pending / devices  
- Share join link  

### 7.5 Participant

- Home: Find room (LAN) **atau** Join via Link (Cloud)  
- Waiting for judge  
- Sharing console + audio panel (mic mute, share mic toggle, quality)  

### 7.6 Web-specific

- Judge web: layout sama, stream via WebRTC `<video>`  
- Participant web: `getDisplayMedia` (tab/window); label jelas “capture terbatas vs desktop app”  
- Responsive breakpoints: 1920 HUD, laptop judge, tablet spectator (fase 2)  

---

## 8. Audio (Cloud)

Port dari `lancast_webrtc` audio settings:

- Enumerate input/output (di mana platform izinkan)  
- Mute mic / mute speakers (judge: mute all remote)  
- Test mic / test speaker  
- Optional AGC/AEC/NS flags  
- Mic track hanya setelah approved + user opt-in share microphone  

Browser: ikuti permission model; jangan asumsikan device ID API sama dengan desktop.

---

## 9. Security & privacy

1. Signaling **WSS only** di cloud  
2. Tidak ada media sebelum approve + token  
3. Revoke → putus PC + invalidate token  
4. PIN hashed (argon2id / scrypt; migrasi dari SHA-256 LAN OK dengan versioning)  
5. ICE TURN credential **ephemeral**, short TTL  
6. Rate-limit `JOIN_REQUEST` per room/IP  
7. Redact tokens di log (`redactToken`)  
8. Room code unguessable; optional judge password  
9. Data residency: default self-hostable stack  
10. Mode LAN tetap bisa **tanpa** mengirim telemetry ke cloud  

---

## 10. Stack usulan (Cloud MVP)

| Layer | Pilihan default | Alternatif |
|-------|-----------------|------------|
| Client desktop | Flutter (existing apps) | — |
| Client web Judge | Flutter Web **atau** React + canvas HUD | Samakan design tokens Arena |
| Signaling | Node/Go WebSocket service | Elixir / Cloudflare Workers + Durable Objects |
| Room DB | Postgres | SQLite + Litestream (small deploy) |
| Auth | Magic link / JWT session | Keycloak / Clerk (opsional) |
| TURN | coturn | Twilio/Metered (biaya) |
| Deploy | Docker Compose | k8s later |

**Jangan** rewrite protocol models di `lancast_core` dari nol — extend.

---

## 11. Layout repo target (Cloud)

```text
apps/viewer/                 # Arena desktop (LAN + cloud client mode)
apps/sender/                 # Participant desktop
apps/judge_web/              # NEW — Judge/Arena web
apps/sender_web/             # NEW — optional limited participant
services/signaling/          # NEW — WSS + room + battle sync
services/turn/               # NEW — coturn config
packages/lancast_core/       # envelope + payloads (+ cloud events)
packages/lancast_arena/      # HUD widgets (reuse web via flutter web atau port)
packages/lancast_webrtc/     # peers + audio
infra/docker-compose.yml     # signaling + turn + db
docs/agent/PROTOCOL_CLOUD.md
skilll-cloud.md              # dokumen ini
```

---

## 12. Data model (Cloud ringkas)

```text
Organization { id, name }
User { id, email, role: org_admin|judge }
BattleRoom {
  room_id, name, category, duration_sec, countdown_sec,
  security_mode, pin_hash?, status, created_by, mode: lan|cloud|hybrid
}
TeamSlot { room_id, slot_index 0..3, team_name, player_name?, device_id?, score }
JoinRequest { request_id, room_id, device, status, created_at }
AccessToken { value_hash, room_id, device_id, permission, expires_at, revoked_at? }
BattleState { room_id, phase, remaining_ms, updated_at }
```

---

## 13. Urutan implementasi Cloud (fase)

### Fase C0 — Spec lock
- [ ] Finalkan dokumen ini + PROTOCOL_CLOUD draft  
- [ ] Design tokens Arena diekspor (warna, type scale)  

### Fase C1 — Signaling cloud
- [ ] Service WSS menerima envelope existing  
- [ ] `ROOM_SUBSCRIBE`, auth judge session  
- [ ] ICE servers endpoint  

### Fase C2 — Join link HTTPS
- [ ] Short link resolve  
- [ ] Sender desktop: Join via Link → cloud WSS  
- [ ] Share dialog menampilkan HTTPS + `lancast://`  

### Fase C3 — Battle sync
- [ ] `BATTLE_PHASE` / `BATTLE_SCORE` / `TEAM_SLOT_UPDATE`  
- [ ] Timer server-authoritative (anti-desync)  

### Fase C4 — Judge Web
- [ ] Create battle, lobby, approval, HUD 2×2, judge controls  
- [ ] Responsive grid (no clipping)  

### Fase C5 — Hardening
- [ ] TURN failover, heartbeat, revoke, rate limit  
- [ ] Load test 1 room × 4 senders @ 720p30  

### Fase C6 — Optional
- [ ] Spectator  
- [ ] SFU  
- [ ] Recording  
- [ ] Chat / remote pointer  

**Jangan** mulai C4 sebelum C1–C2 jalan (sama seperti LAN: jangan WebRTC sebelum approval+token).

---

## 14. Definition of Done — Cloud MVP demo

- [ ] Judge buat room cloud → dapat HTTPS join link  
- [ ] 4 participant (bisa beda jaringan) join → waiting → approve  
- [ ] Arena HUD menampilkan 4 stream tanpa terpotong  
- [ ] Timer countdown → running → warning → finished sync di semua client  
- [ ] Score update terlihat di HUD  
- [ ] Mic share opsional + judge mute speakers  
- [ ] Revoke participant → stream mati  
- [ ] Mode LAN existing **tidak regres** (`make test`, demo LAN masih hijau)  

---

## 15. Guardrails khusus Cloud

- Jangan hardcode TURN password di client repo  
- Jangan log `token.value` / TURN credential  
- Jangan wajibkan akun untuk participant MVP (anon display name OK)  
- Jangan anggap Flutter Web = desktop capture  
- Jangan pecahkan `lancast://` link LAN  
- Satu battle room aktif per judge session (MVP), sama seperti satu room per Viewer LAN  

---

## 16. Mapping ke kode existing (referensi agent)

| Existing | Cloud reuse |
|----------|-------------|
| `packages/lancast_core` | + cloud payloads / join HTTPS resolve DTO |
| `packages/lancast_arena` | HUD widgets Judge Web / Flutter Web |
| `packages/lancast_webrtc` | SenderPeer/ViewerPeer + audio; inject ICE from server |
| `packages/lancast_signaling` | Client WSS tetap; server diganti/ditambah cloud service |
| `apps/viewer` Arena screens | Mode selector LAN \| Cloud |
| `apps/sender` Join via Link | Parse HTTPS resolve + `lancast://` |
| `RoomJoinLink` | Extend encode/decode cloud URLs |
| `docs/RUN.md` / export | Tambah “deploy signaling” runbook |

---

## 17. Open questions (isi sebelum coding besar)

1. Self-host only atau SaaS managed?  
2. Flutter Web vs React untuk Judge Web?  
3. Mesh WebRTC cukup untuk 4×720p atau langsung SFU?  
4. Auth participant: total anon atau email wajib?  
5. Domain produksi join link?  
6. Apakah cloud room boleh sekaligus di-announce ke LAN (hybrid)?  

---

## 18. Satu kalimat arah produk

> **LanCast Cloud** membawa Arena Command Center (4-team HUD, timer, judge, audio, join link) ke internet dengan signaling/TURN terpusat, sambil menjaga LanCast LAN sebagai mode offline kelas satu.

---

**Draft skill file:** `skilll-cloud.md`  
**Sumber kebenaran LAN:** `skilll.md`  
**Agent playbooks LAN:** `AGENTS.md`, `docs/agent/`  

Saat Cloud masuk eksekusi: buat `docs/agent/BUILD_PLAN_CLOUD.md` + `PROTOCOL_CLOUD.md`, dan update `AGENTS.md` dengan pointer ke dokumen ini.
