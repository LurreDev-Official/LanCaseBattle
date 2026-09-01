import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('generateRoomId is stable format', () {
    final id = generateRoomId('Training Room A');
    expect(id, startsWith('TRAINING-ROOM-A-'));
    expect(id.split('-').last, hasLength(3));
  });

  test('announcer + scanner loopback discovers room', () async {
    final port = 19000 + DateTime.now().millisecond % 500;
    final announcer = DiscoveryAnnouncer(
      port: port,
      interval: const Duration(milliseconds: 200),
    );
    final scanner = DiscoveryScanner(
      port: port,
      staleAfter: const Duration(seconds: 3),
    );

    await scanner.start();
    final seen = scanner.rooms$.firstWhere((rooms) => rooms.isNotEmpty);

    await announcer.start(
      RoomAnnouncePayload(
        roomId: 'TEST-ROOM-1',
        name: 'Test Room',
        ownerName: 'Host',
        securityMode: SecurityMode.approvalRequired,
        pinRequired: false,
        wsUrl: 'ws://127.0.0.1:${LancastConstants.signalingPort}',
        status: RoomAnnounceStatus.open,
        protocolV: LancastConstants.protocolVersion,
      ),
    );

    final rooms = await seen.timeout(const Duration(seconds: 3));
    expect(rooms.single.roomId, 'TEST-ROOM-1');
    expect(rooms.single.name, 'Test Room');

    await announcer.stop();
    await scanner.dispose();
  });
}
