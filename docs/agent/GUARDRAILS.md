# Guardrails — Jangan Dilanggar

## Keamanan & produk

| Larangan | Alasan |
|----------|--------|
| Stream / `getDisplayMedia` sebelum `JOIN_APPROVED` | Controlled access |
| Simpan PIN plaintext di DB/log | Spek keamanan |
| Log full token | Leak sesi |
| Cloud auth, Firebase, Supabase, dll. untuk join | LAN-only |
| Telemetry wajib / analytics yang butuh internet | Privacy MVP |
| Auto-join tanpa approval di mode `approval_required` (kecuali resume token valid) | Spek |

## Arsitektur

| Larangan | Lakukan ini |
|----------|-------------|
| Signaling server di Sender | Host hanya di Viewer |
| `apps/viewer` import fitur sender atau sebaliknya | Shared lewat `packages/*` |
| Magic string event di widgets | Pakai `lancast_core` |
| Bypass token check di `SIGNAL_*` “untuk cepat demo” | Gate tetap; pakai mock approved di test |
| Multi-room paralel di MVP | Satu room aktif / Viewer |

## Scope creep (tolak kecuali user minta eksplisit)

- Audio share, chat, remote pointer
- Rekaman sesi, cloud relay / TURN publik sebagai dependency wajib
- iOS Broadcast Extension
- Custom E2E crypto di atas WS
- Mode `trusted_device_only` penuh (selain resume token)
- Web viewer production-ready

Jika diminta fitur di atas: **stop**, tanya user, jangan diam-diam masukkan ke MVP.

## Kualitas kode

- Jangan commit secrets (`.env` dengan kredensial, private keys)
- Jangan `flutter pub add` paket besar di luar stack di `AGENTS.md` tanpa alasan di PR/ringkasan
- Prefer minimal diff per fase
- Jangan rewrite spek (`skilll.md`) saat coding kecuali user minta
- Konflik produk vs kenyamanan implementasi → ikuti `skilll.md` / tanya user

## Testing

- Jangan anggap “UI sudah kebuka” sebagai DoD fase 3+ — event + status harus terverifikasi
- Jangan skip unit test envelope/token TTL
- WebRTC: manual OK; jangan klaim DoD fase 5 tanpa video terlihat

## Konflik dokumen

1. Wire JSON / `type` → `PROTOCOL.md`
2. Produk / MVP scope → `skilll.md`
3. Urutan kerja → `BUILD_PLAN.md`
4. Aturan singkat session → `AGENTS.md`
