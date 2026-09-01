import 'package:lancast_core/lancast_core.dart';
import 'package:test/test.dart';

void main() {
  group('RoomJoinLink', () {
    final room = RoomAnnouncePayload(
      roomId: 'ARENA-42',
      name: 'OPEN CUP',
      ownerName: 'Judge-PC',
      securityMode: SecurityMode.approvalRequired,
      pinRequired: true,
      wsUrl: 'ws://192.168.1.10:17890',
      status: RoomAnnounceStatus.open,
      protocolV: 1,
    );

    test('round-trip encode/decode', () {
      final link = RoomJoinLink.encodeString(room);
      expect(link, startsWith('lancast://join?'));
      final decoded = RoomJoinLink.tryDecode(link);
      expect(decoded, isNotNull);
      expect(decoded!.roomId, room.roomId);
      expect(decoded.name, room.name);
      expect(decoded.wsUrl, room.wsUrl);
      expect(decoded.ownerName, room.ownerName);
      expect(decoded.pinRequired, isTrue);
      expect(decoded.securityMode, SecurityMode.approvalRequired);
    });

    test('short form decode', () {
      final decoded =
          RoomJoinLink.tryDecode('lancast://join/ARENA-42@192.168.1.10:17890');
      expect(decoded, isNotNull);
      expect(decoded!.roomId, 'ARENA-42');
      expect(decoded.wsUrl, 'ws://192.168.1.10:17890');
    });

    test('rejects garbage', () {
      expect(RoomJoinLink.tryDecode(''), isNull);
      expect(RoomJoinLink.tryDecode('https://example.com'), isNull);
      expect(RoomJoinLink.tryDecode('lancast://join?room_id=x'), isNull);
    });
  });
}
