import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lancast_core/lancast_core.dart';

/// Periodically broadcasts [RoomAnnouncePayload] over UDP.
class DiscoveryAnnouncer {
  DiscoveryAnnouncer({
    this.port = LancastConstants.udpBroadcastPort,
    this.interval = const Duration(seconds: 2),
  });

  final int port;
  final Duration interval;

  RawDatagramSocket? _socket;
  Timer? _timer;
  RoomAnnouncePayload? _payload;
  bool _running = false;

  bool get isRunning => _running;
  RoomAnnouncePayload? get currentPayload => _payload;

  Future<void> start(RoomAnnouncePayload payload) async {
    await stop();
    _payload = payload;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
    _running = true;
    _sendOnce();
    _timer = Timer.periodic(interval, (_) => _sendOnce());
  }

  void updatePayload(RoomAnnouncePayload payload) {
    _payload = payload;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    _running = false;
    _payload = null;
  }

  void _sendOnce() {
    final payload = _payload;
    final socket = _socket;
    if (payload == null || socket == null) return;

    final envelope = Envelope.create(
      type: EventType.roomAnnounce,
      roomId: payload.roomId,
      payload: payload.toJson(),
    );
    final bytes = utf8.encode(envelope.toJsonString());

    // Broadcast for LAN peers.
    socket.send(bytes, InternetAddress('255.255.255.255'), port);
    // Loopback for same-host viewer+sender testing.
    socket.send(bytes, InternetAddress.loopbackIPv4, port);
  }
}
