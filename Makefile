.PHONY: run run-manual run-apps deps test analyze stop export export-macos export-windows help

help:
	@echo "LanCast commands:"
	@echo "  make run           One-shot: Viewer + Sender (AUTO_ROOM=true)"
	@echo "  make run-manual    One-shot without auto room"
	@echo "  make run-apps      Build debug .app then open both (macOS)"
	@echo "  make export        Release export for this OS → dist/"
	@echo "  make export-macos  Release export macOS .app + zip"
	@echo "  make export-windows  (run on Windows) Release exe folders + zip"
	@echo "  make deps          dart pub get (workspace)"
	@echo "  make test          Run package tests"
	@echo "  make analyze       Analyze viewer + sender"
	@echo "  make stop          Kill running LanCast flutter/app processes"
	@echo "  Docs: docs/RUN.md"

deps:
	dart pub get

run:
	LANCAST_AUTO_ROOM=true ./scripts/run.sh

run-manual:
	LANCAST_AUTO_ROOM=false ./scripts/run.sh

run-apps:
	./scripts/run_release_apps.sh

export export-macos:
	./scripts/export.sh macos

export-windows:
	./scripts/export.sh windows

test:
	dart pub get
	cd packages/lancast_core && dart test
	cd packages/lancast_discovery && dart test
	cd packages/lancast_signaling && dart test

analyze:
	cd apps/viewer && dart analyze lib
	cd apps/sender && dart analyze lib

stop:
	pkill -f 'lancast_viewer.app' 2>/dev/null || true
	pkill -f 'lancast_sender.app' 2>/dev/null || true
	pkill -f 'LanCast Arena' 2>/dev/null || true
	pkill -f 'LanCast Participant' 2>/dev/null || true
	pkill -f 'apps/viewer.*flutter run' 2>/dev/null || true
	pkill -f 'apps/sender.*flutter run' 2>/dev/null || true
	@echo "Stopped LanCast processes (if any)."
