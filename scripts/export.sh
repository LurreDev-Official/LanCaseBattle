#!/usr/bin/env bash
# Export LanCast release apps into dist/
# Usage:
#   ./scripts/export.sh           # auto-detect host OS
#   ./scripts/export.sh macos
#   ./scripts/export.sh windows   # must run on Windows (Git Bash / WSL with Flutter Windows)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/config/lancast.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "$ROOT/config/lancast.env"
  set +a
fi

resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN}/flutter" ]]; then
    export PATH="${FLUTTER_BIN}:$PATH"
    return
  fi
  if command -v flutter >/dev/null 2>&1; then
    return
  fi
  for candidate in \
    /Applications/development/flutter/bin \
    "$HOME/flutter/bin" \
    "$HOME/development/flutter/bin"; do
    if [[ -x "$candidate/flutter" ]]; then
      export PATH="$candidate:$PATH"
      return
    fi
  done
  echo "ERROR: flutter not found. Set FLUTTER_BIN in config/lancast.env" >&2
  exit 1
}

resolve_flutter

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  case "$(uname -s)" in
    Darwin) TARGET=macos ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) TARGET=windows ;;
    *)
      echo "ERROR: unknown OS. Pass macos or windows explicitly." >&2
      exit 1
      ;;
  esac
fi

VERSION="$(grep -E '^version:' apps/viewer/pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)"
VERSION="${VERSION:-0.1.0}"
STAMP="$(date +%Y%m%d-%H%M)"
OUT="$ROOT/dist/${TARGET}/LanCast-${VERSION}-${STAMP}"
mkdir -p "$OUT"

echo "═══ LanCast export ═══"
echo "Target : $TARGET"
echo "Version: $VERSION"
echo "Output : $OUT"
echo ""

echo "→ dart pub get"
dart pub get >/dev/null

case "$TARGET" in
  macos)
    echo "→ flutter build macos --release (Viewer)"
    (
      cd apps/viewer
      flutter build macos --release
    )
    echo "→ flutter build macos --release (Sender)"
    (
      cd apps/sender
      flutter build macos --release
    )

    VIEWER_SRC="$ROOT/apps/viewer/build/macos/Build/Products/Release/lancast_viewer.app"
    SENDER_SRC="$ROOT/apps/sender/build/macos/Build/Products/Release/lancast_sender.app"

    if [[ ! -d "$VIEWER_SRC" || ! -d "$SENDER_SRC" ]]; then
      echo "ERROR: release .app not found" >&2
      exit 1
    fi

    rm -rf "$OUT/LanCast Arena.app" "$OUT/LanCast Participant.app"
    cp -R "$VIEWER_SRC" "$OUT/LanCast Arena.app"
    cp -R "$SENDER_SRC" "$OUT/LanCast Participant.app"

    cat >"$OUT/CARA_PAKAI.txt" <<EOF
LanCast Arena — macOS Release
=============================

1. Buka folder ini di Finder.
2. Jalankan "LanCast Arena.app" (Judge / Viewer / Host).
3. Jalankan "LanCast Participant.app" (Sender / peserta).
4. Kedua PC harus di jaringan Wi-Fi/LAN yang sama.
5. Arena: Create Battle Room → Share Join Link.
6. Participant: Scan Rooms atau Join via Link → minta Approve.
7. Setelah approve: Start Share (izinkan Screen Recording).

Catatan keamanan macOS
----------------------
Jika Gatekeeper memblokir app (unsigned):
  System Settings → Privacy & Security → Open Anyway
atau:
  xattr -dr com.apple.quarantine "LanCast Arena.app"
  xattr -dr com.apple.quarantine "LanCast Participant.app"

Izin yang dibutuhkan
--------------------
- LanCast Arena: Local Network (UDP discovery + WebSocket)
- LanCast Participant: Screen Recording + Microphone (opsional) + Local Network
EOF

    ZIP="$ROOT/dist/LanCast-macos-${VERSION}-${STAMP}.zip"
    echo "→ zipping $ZIP"
    (
      cd "$OUT/.."
      ditto -c -k --sequesterRsrc --keepParent "$(basename "$OUT")" "$ZIP"
    )
    echo ""
    echo "Done."
    echo "  Apps : $OUT"
    echo "  Zip  : $ZIP"
    ;;

  windows)
    if ! flutter config --list 2>/dev/null | grep -q 'enable-windows-desktop: true'; then
      echo "→ enabling Windows desktop"
      flutter config --enable-windows-desktop >/dev/null || true
    fi

    echo "→ flutter build windows --release (Viewer)"
    (
      cd apps/viewer
      flutter build windows --release
    )
    echo "→ flutter build windows --release (Sender)"
    (
      cd apps/sender
      flutter build windows --release
    )

    VIEWER_SRC="$ROOT/apps/viewer/build/windows/x64/runner/Release"
    SENDER_SRC="$ROOT/apps/sender/build/windows/x64/runner/Release"

    if [[ ! -d "$VIEWER_SRC" || ! -d "$SENDER_SRC" ]]; then
      # Older Flutter layouts
      VIEWER_SRC="$ROOT/apps/viewer/build/windows/runner/Release"
      SENDER_SRC="$ROOT/apps/sender/build/windows/runner/Release"
    fi

    if [[ ! -d "$VIEWER_SRC" || ! -d "$SENDER_SRC" ]]; then
      echo "ERROR: Windows Release folder not found. Build on a Windows machine with VS Build Tools." >&2
      exit 1
    fi

    mkdir -p "$OUT/LanCast Arena" "$OUT/LanCast Participant"
    cp -R "$VIEWER_SRC/." "$OUT/LanCast Arena/"
    cp -R "$SENDER_SRC/." "$OUT/LanCast Participant/"

    cat >"$OUT/CARA_PAKAI.txt" <<EOF
LanCast Arena — Windows Release
===============================

1. Jalankan "LanCast Arena\\lancast_viewer.exe" (Judge / Viewer).
2. Jalankan "LanCast Participant\\lancast_sender.exe" (Sender).
3. Kedua PC harus di jaringan LAN/Wi-Fi yang sama.
4. Izinkan Windows Firewall untuk aplikasi saat diminta (UDP 17891, TCP 17890).
5. Arena: Create Battle Room → Share Join Link.
6. Participant: Scan Rooms / Join via Link → tunggu Approve → Start Share.

Catatan
-------
Folder Release harus tetap utuh (DLL + data). Jangan pindahkan .exe saja.
EOF

    ZIP="$ROOT/dist/LanCast-windows-${VERSION}-${STAMP}.zip"
    echo "→ zipping $ZIP"
    if command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -NoProfile -Command \
        "Compress-Archive -Path '$(cygpath -w "$OUT" 2>/dev/null || echo "$OUT")' -DestinationPath '$(cygpath -w "$ZIP" 2>/dev/null || echo "$ZIP")' -Force"
    elif command -v zip >/dev/null 2>&1; then
      (
        cd "$OUT/.."
        zip -r "$ZIP" "$(basename "$OUT")"
      )
    else
      echo "WARN: zip tool not found; folder export only at $OUT"
    fi
    echo ""
    echo "Done."
    echo "  Apps : $OUT"
    echo "  Zip  : $ZIP"
    ;;

  *)
    echo "ERROR: unsupported target '$TARGET' (use macos|windows)" >&2
    exit 1
    ;;
esac
