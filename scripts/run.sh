#!/usr/bin/env bash
# One-shot LanCast launcher: Viewer + Sender together.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Load config
if [[ -f "$ROOT/config/lancast.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "$ROOT/config/lancast.env"
  set +a
fi

DEVICE="${LANCAST_DEVICE:-macos}"
AUTO_ROOM="${LANCAST_AUTO_ROOM:-true}"
EXTRA_ARGS="${LANCAST_FLUTTER_ARGS:-}"

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

VIEWER_PID=""
SENDER_PID=""
VIEWER_LOG="$ROOT/.lancast/viewer.log"
SENDER_LOG="$ROOT/.lancast/sender.log"
mkdir -p "$ROOT/.lancast"

cleanup() {
  echo ""
  echo "Stopping LanCast…"
  [[ -n "$VIEWER_PID" ]] && kill "$VIEWER_PID" 2>/dev/null || true
  [[ -n "$SENDER_PID" ]] && kill "$SENDER_PID" 2>/dev/null || true
  # Also stop child flutter/dart if needed
  pkill -f "apps/viewer .*flutter run" 2>/dev/null || true
  pkill -f "apps/sender .*flutter run" 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

echo "═══ LanCast one-shot ═══"
echo "Device   : $DEVICE"
echo "Auto room: $AUTO_ROOM"
echo "Root     : $ROOT"
echo ""

echo "→ dart pub get"
dart pub get >/dev/null

VIEWER_DEFINE=()
if [[ "$AUTO_ROOM" == "true" || "$AUTO_ROOM" == "1" ]]; then
  VIEWER_DEFINE+=(--dart-define=AUTO_ROOM=true)
fi

echo "→ starting Viewer (log: .lancast/viewer.log)"
(
  cd "$ROOT/apps/viewer"
  # shellcheck disable=SC2086
  flutter run -d "$DEVICE" "${VIEWER_DEFINE[@]}" $EXTRA_ARGS
) >"$VIEWER_LOG" 2>&1 &
VIEWER_PID=$!

echo "→ starting Sender (log: .lancast/sender.log)"
(
  cd "$ROOT/apps/sender"
  # shellcheck disable=SC2086
  flutter run -d "$DEVICE" $EXTRA_ARGS
) >"$SENDER_LOG" 2>&1 &
SENDER_PID=$!

echo ""
echo "Both apps launching…"
echo "  Viewer PID: $VIEWER_PID"
echo "  Sender PID: $SENDER_PID"
echo ""
echo "Tips:"
echo "  • Viewer dashboard: approve join requests"
echo "  • Sender: Scan Rooms → Request Join → Start Share"
echo "  • Logs: tail -f .lancast/viewer.log   /   .lancast/sender.log"
echo "  • Stop: Ctrl+C"
echo ""

# Wait until both exit (or user hits Ctrl+C)
wait "$VIEWER_PID" "$SENDER_PID" 2>/dev/null || true
cleanup
