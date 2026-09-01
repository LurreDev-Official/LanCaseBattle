# LanCast — Agent Docs Index

Dokumen ini untuk AI coding agent. Baca urutan ini sebelum coding.

| # | File | Kapan dibaca |
|---|------|----------------|
| 0 | [`../../AGENTS.md`](../../AGENTS.md) | Selalu — aturan singkat |
| 1 | [`../../skilll.md`](../../skilll.md) | Spesifikasi produk & MVP |
| 2 | [`ARCHITECTURE.md`](ARCHITECTURE.md) | Struktur app, package, tanggung jawab |
| 3 | [`PROTOCOL.md`](PROTOCOL.md) | Envelope, events, state machine |
| 4 | [`BUILD_PLAN.md`](BUILD_PLAN.md) | Fase implementasi berurutan |
| 5 | [`TASKS.md`](TASKS.md) | Checklist atomik + acceptance |
| 6 | [`GUARDRAILS.md`](GUARDRAILS.md) | Larangan & anti-pola |

## Cara kerja agent

1. Ambil **satu fase** dari `BUILD_PLAN.md` (atau satu task dari `TASKS.md`).
2. Implement sesuai `ARCHITECTURE.md` + `PROTOCOL.md`.
3. Verifikasi acceptance criteria task.
4. Jangan mulai fase berikutnya jika DoD fase belum terpenuhi.
5. Jika konflik antar dokumen: `skilll.md` menang untuk produk; `PROTOCOL.md` menang untuk wire format.
