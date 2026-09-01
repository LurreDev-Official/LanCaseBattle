#!/usr/bin/env bash
# Build once, then open both macOS .app bundles (faster relaunch after first build).
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
  echo "ERROR: flutter not found" >&2
  exit 1
}

resolve_flutter

AUTO_ROOM="${LANCAST_AUTO_ROOM:-true}"
VIEWER_DEFINE=()
if [[ "$AUTO_ROOM" == "true" || "$AUTO_ROOM" == "1" ]]; then
  VIEWER_DEFINE+=(--dart-define=AUTO_ROOM=true)
fi

echo "→ Building Viewer…"
(
  cd apps/viewer
  flutter build macos --debug "${VIEWER_DEFINE[@]}"
)

echo "→ Building Sender…"
(
  cd apps/sender
  flutter build macos --debug
)

VIEWER_APP="$ROOT/apps/viewer/build/macos/Build/Products/Debug/lancast_viewer.app"
SENDER_APP="$ROOT/apps/sender/build/macos/Build/Products/Debug/lancast_sender.app"

echo "→ Opening apps"
open "$VIEWER_APP"
open "$SENDER_APP"

echo "Done. Viewer + Sender are open."
if [[ "$AUTO_ROOM" == "true" || "$AUTO_ROOM" == "1" ]]; then
  echo "Viewer should auto-create a room (AUTO_ROOM)."
fi
