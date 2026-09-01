import 'package:lancast_core/lancast_core.dart';
import 'package:test/test.dart';

void main() {
  group('Envelope', () {
    test('round-trips JSON', () {
      final original = Envelope.create(
        type: EventType.joinRequest,
        roomId: 'TRAIN-A001',
        ts: DateTime.utc(2026, 8, 11, 3, 15, 20),
        payload: {
          'request_id': 'req-1',
          'device': {
            'device_id': 'dev-1',
            'name': 'Laptop-Andi',
            'os': 'windows',
          },
          'pin': null,
          'resume_token': null,
        },
      );

      final restored = Envelope.fromJsonString(original.toJsonString());

      expect(restored.v, LancastConstants.protocolVersion);
      expect(restored.type, EventType.joinRequest);
      expect(restored.roomId, 'TRAIN-A001');
      expect(restored.ts.toUtc(), DateTime.utc(2026, 8, 11, 3, 15, 20));
      expect(restored.payload['request_id'], 'req-1');
      expect(restored.isSupportedVersion, isTrue);
      expect(restored.isKnownType, isTrue);
    });

    test('unknown type does not throw and is flagged', () {
      final envelope = Envelope.fromJson({
        'v': 1,
        'type': 'SOMETHING_NEW',
        'room_id': 'R1',
        'ts': '2026-08-11T10:15:20+07:00',
        'payload': {},
      });
      expect(envelope.isKnownType, isFalse);
      expect(parsePayload(envelope), isNull);
    });
  });

  group('payloads', () {
    test('JoinRequestPayload round-trip via envelope', () {
      final payload = JoinRequestPayload(
        requestId: 'uuid',
        device: const DeviceInfo(
          deviceId: 'uuid-stable',
          name: 'Laptop-Andi',
          username: 'Andi',
          os: 'windows',
          osVersion: '11',
          ip: '192.168.1.45',
          appVersion: '0.1.0',
        ),
      );
      final envelope = Envelope.create(
        type: EventType.joinRequest,
        roomId: 'TRAIN-A001',
        payload: payload.toJson(),
      );
      final parsed = parsePayload(envelope) as JoinRequestPayload;
      expect(parsed.requestId, 'uuid');
      expect(parsed.device.name, 'Laptop-Andi');
      expect(parsed.device.ip, '192.168.1.45');
    });

    test('JoinApprovedPayload includes token expiry', () {
      final expires = DateTime.utc(2026, 8, 12, 3, 15, 20);
      final payload = JoinApprovedPayload(
        requestId: 'uuid',
        deviceId: '001',
        token: AccessToken(
          value: 'opaque',
          permission: LancastConstants.permissionScreenShare,
          expiresAt: expires,
        ),
      );
      final envelope = Envelope.create(
        type: EventType.joinApproved,
        roomId: 'TRAIN-A001',
        payload: payload.toJson(),
      );
      final parsed = parsePayload(envelope) as JoinApprovedPayload;
      expect(parsed.token.value, 'opaque');
      expect(parsed.token.expiresAt.toUtc(), expires);
      expect(parsed.token.isExpired, isFalse);
    });

    test('RoomAnnouncePayload security mode wire format', () {
      final payload = RoomAnnouncePayload(
        roomId: 'TRAIN-A001',
        name: 'TRAINING ROOM A',
        ownerName: 'Main-PC',
        securityMode: SecurityMode.approvalRequired,
        pinRequired: true,
        wsUrl: 'ws://192.168.1.10:17890',
        status: RoomAnnounceStatus.open,
        protocolV: 1,
      );
      expect(payload.toJson()['security_mode'], 'approval_required');
      final restored = RoomAnnouncePayload.fromJson(payload.toJson());
      expect(restored.securityMode, SecurityMode.approvalRequired);
    });
  });
}
