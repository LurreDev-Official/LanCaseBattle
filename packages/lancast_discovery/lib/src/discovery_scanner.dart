import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lancast_core/lancast_core.dart';

/// Listens for UDP [ROOM_ANNOUNCE] and exposes a stream of rooms.
class DiscoveryScanner {
  DiscoveryScanner({
    this.port = LancastConstants.udpBroadcastPort,
    this.staleAfter = const Duration(seconds: 8),
  });

  final int port;
  final Duration staleAfter;

  RawDatagramSocket? _socket;
  Timer? _pruneTimer;
  final _rooms = <String, _TrackedRoom>{};
  final _controller = StreamController<List<RoomAnnouncePayload>>.broadcast();
  bool _running = false;

  bool get isRunning => _running;
  Stream<List<RoomAnnouncePayload>> get rooms$ => _controller.stream;
  List<RoomAnnouncePayload> get currentRooms =>
      _rooms.values.map((e) => e.payload).toList(growable: false);

  Future<void> start() async {
    if (_running) return;
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: true,
    );
    _socket!.broadcastEnabled = true;
    _running = true;

    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;
      _handleDatagram(datagram.data);
    });
    // Drain any already-queued datagrams.
    while (true) {
      final datagram = _socket!.receive();
      if (datagram == null) break;
      _handleDatagram(datagram.data);
    }

    _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) => _prune());
  }

  Future<void> stop() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    _socket?.close();
    _socket = null;
    _rooms.clear();
    _running = false;
    if (!_controller.isClosed) {
      _controller.add(const []);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _handleDatagram(List<int> data) {
    try {
      final text = utf8.decode(data);
      final envelope = Envelope.fromJsonString(text);
      if (!envelope.isSupportedVersion) return;
      if (envelope.type != EventType.roomAnnounce) return;
      final payload = RoomAnnouncePayload.fromJson(envelope.payload);
      if (payload.roomId.isEmpty || payload.wsUrl.isEmpty) return;
      if (payload.status != RoomAnnounceStatus.open) {
        _rooms.remove(payload.roomId);
        _emit();
        return;
      }
      _rooms[payload.roomId] = _TrackedRoom(
        payload: payload,
        lastSeen: DateTime.now().toUtc(),
      );
      _emit();
    } catch (_) {
      // Ignore malformed discovery packets.
    }
  }

  void _prune() {
    final cutoff = DateTime.now().toUtc().subtract(staleAfter);
    final before = _rooms.length;
    _rooms.removeWhere((_, tracked) => tracked.lastSeen.isBefore(cutoff));
    if (_rooms.length != before) {
      _emit();
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(currentRooms);
    }
  }
}

class _TrackedRoom {
  _TrackedRoom({required this.payload, required this.lastSeen});
  RoomAnnouncePayload payload;
  DateTime lastSeen;
}
