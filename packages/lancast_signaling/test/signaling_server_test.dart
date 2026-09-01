import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_signaling/lancast_signaling.dart';
import 'package:test/test.dart';

void main() {
  test('server accepts client and relays envelope', () async {
    final port = 20000 + DateTime.now().millisecond % 400;
    final server = SignalingServer(port: port);
    await server.start();
    addTearDown(server.dispose);

    final received = server.envelopes$.first;
    final client = SignalingClient();
    await client.connect(Uri.parse('ws://127.0.0.1:$port'));
    addTearDown(client.dispose);

    final envelope = Envelope.create(
      type: EventType.heartbeat,
      roomId: 'R1',
      payload: const HeartbeatPayload(deviceId: 'd1', seq: 1).toJson(),
    );
    client.send(envelope);

    final pair = await received.timeout(const Duration(seconds: 3));
    expect(pair.$2.type, EventType.heartbeat);
    expect(pair.$2.roomId, 'R1');
  });
}
