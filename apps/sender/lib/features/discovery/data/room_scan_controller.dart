import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:logger/logger.dart';

final roomScanProvider =
    StateNotifierProvider<RoomScanController, RoomScanState>((ref) {
  return RoomScanController();
});

class RoomScanState {
  const RoomScanState({
    this.rooms = const [],
    this.isScanning = false,
    this.error,
    this.selected,
  });

  final List<RoomAnnouncePayload> rooms;
  final bool isScanning;
  final String? error;
  final RoomAnnouncePayload? selected;

  RoomScanState copyWith({
    List<RoomAnnouncePayload>? rooms,
    bool? isScanning,
    String? error,
    RoomAnnouncePayload? selected,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return RoomScanState(
      rooms: rooms ?? this.rooms,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : (error ?? this.error),
      selected: clearSelected ? null : (selected ?? this.selected),
    );
  }
}

class RoomScanController extends StateNotifier<RoomScanState> {
  RoomScanController({
    DiscoveryScanner? scanner,
    Logger? logger,
  })  : _scanner = scanner ?? DiscoveryScanner(),
        _log = logger ?? Logger(),
        super(const RoomScanState());

  final DiscoveryScanner _scanner;
  final Logger _log;
  StreamSubscription<List<RoomAnnouncePayload>>? _sub;

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      await _scanner.start();
      _sub = _scanner.rooms$.listen((rooms) {
        final nextIds = rooms.map((r) => r.roomId).join(',');
        final prevIds = state.rooms.map((r) => r.roomId).join(',');
        if (nextIds != prevIds) {
          _log.i('Rooms updated: ${rooms.map((r) => '${r.name} (${r.roomId})').join(', ')}');
        }
        state = state.copyWith(rooms: List.of(rooms));
      });
      state = state.copyWith(rooms: List.of(_scanner.currentRooms));
      _log.i('Discovery scan started on UDP ${LancastConstants.udpBroadcastPort}');
    } catch (e, st) {
      _log.e('Scan failed', error: e, stackTrace: st);
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  Future<void> stopScan() async {
    await _sub?.cancel();
    _sub = null;
    await _scanner.stop();
    state = state.copyWith(isScanning: false, rooms: const []);
  }

  void selectRoom(RoomAnnouncePayload room) {
    state = state.copyWith(selected: room);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_scanner.dispose());
    super.dispose();
  }
}
