import 'dart:async';

import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_signaling/lancast_signaling.dart';
import 'package:test/test.dart';

void main() {
  late SignalingServer server;
  late int port;

  setUp(() async {
    port = 21000 + DateTime.now().microsecond % 800;
    server = SignalingServer(port: port);
    await server.start();
  });

  tearDown(() async {
    await server.dispose();
  });

  test('JOIN_REQUEST → JOIN_APPROVED end-to-end', () async {
    server.onEnvelope = (peer, envelope) {
      if (envelope.type != EventType.joinRequest) return;
      final req = JoinRequestPayload.fromJson(envelope.payload);
      peer.deviceId = req.device.deviceId;
      peer.send(
        Envelope.create(
          type: EventType.joinApproved,
          roomId: envelope.roomId,
          payload: JoinApprovedPayload(
            requestId: req.requestId,
            deviceId: req.device.deviceId,
            token: AccessToken(
              value: 'test-token-abc',
              permission: LancastConstants.permissionScreenShare,
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            ),
          ).toJson(),
        ),
      );
    };

    final client = SignalingClient();
    addTearDown(client.dispose);
    await client.connect(Uri.parse('ws://127.0.0.1:$port'));

    final approved = client.envelopes$.firstWhere(
      (e) => e.type == EventType.joinApproved,
    );

    client.send(
      Envelope.create(
        type: EventType.joinRequest,
        roomId: 'ROOM-1',
        payload: JoinRequestPayload(
          requestId: 'req-1',
          device: const DeviceInfo(
            deviceId: 'dev-1',
            name: 'Laptop-Test',
            os: 'macos',
            ip: '127.0.0.1',
          ),
        ).toJson(),
      ),
    );

    final env = await approved.timeout(const Duration(seconds: 3));
    final payload = JoinApprovedPayload.fromJson(env.payload);
    expect(payload.deviceId, 'dev-1');
    expect(payload.token.value, 'test-token-abc');
  });

  test('JOIN_REQUEST → JOIN_REJECTED end-to-end', () async {
    server.onEnvelope = (peer, envelope) {
      if (envelope.type != EventType.joinRequest) return;
      final req = JoinRequestPayload.fromJson(envelope.payload);
      peer.send(
        Envelope.create(
          type: EventType.joinRejected,
          roomId: envelope.roomId,
          payload: JoinRejectedPayload(
            requestId: req.requestId,
            deviceId: req.device.deviceId,
            reason: 'Admin denied',
          ).toJson(),
        ),
      );
    };

    final client = SignalingClient();
    addTearDown(client.dispose);
    await client.connect(Uri.parse('ws://127.0.0.1:$port'));

    final rejected = client.envelopes$.firstWhere(
      (e) => e.type == EventType.joinRejected,
    );

    client.send(
      Envelope.create(
        type: EventType.joinRequest,
        roomId: 'ROOM-1',
        payload: const JoinRequestPayload(
          requestId: 'req-2',
          device: DeviceInfo(
            deviceId: 'dev-2',
            name: 'Laptop-B',
            os: 'macos',
          ),
        ).toJson(),
      ),
    );

    final env = await rejected.timeout(const Duration(seconds: 3));
    final payload = JoinRejectedPayload.fromJson(env.payload);
    expect(payload.reason, 'Admin denied');
  });

  test('ROOM_CLOSED broadcast reaches client', () async {
    final client = SignalingClient();
    addTearDown(client.dispose);

    final closed = client.envelopes$.firstWhere(
      (e) => e.type == EventType.roomClosed,
    );

    await client.connect(Uri.parse('ws://127.0.0.1:$port'));
    for (var i = 0; i < 20 && server.peerCount < 1; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(server.peerCount, greaterThanOrEqualTo(1));

    server.broadcast(
      Envelope.create(
        type: EventType.roomClosed,
        roomId: 'ROOM-1',
        payload: const RoomClosedPayload(reason: 'admin_closed').toJson(),
      ),
    );

    final env = await closed.timeout(const Duration(seconds: 3));
    expect(env.payload['reason'], 'admin_closed');
  });
}
