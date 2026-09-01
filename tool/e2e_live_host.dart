/// Minimal live host for manual UI testing without Flutter Viewer.
/// Run: dart run tool/e2e_live_host.dart
/// Then use Sender app to scan/join; this host auto-approves.
library;

import 'dart:async';
import 'dart:io';

import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:lancast_signaling/lancast_signaling.dart';

Future<void> main() async {
  final lan = await resolveLanIpv4();
  final hostIp = lan?.address ?? '127.0.0.1';
  final owner = await resolveOwnerName();
  final roomId = generateRoomId('E2E LIVE');
  final port = LancastConstants.signalingPort;

  final server = SignalingServer(port: port);
  final announcer = DiscoveryAnnouncer();

  await server.start();
  final wsUrl = 'ws://$hostIp:${server.boundPort ?? port}';
  final payload = RoomAnnouncePayload(
    roomId: roomId,
    name: 'E2E LIVE',
    ownerName: owner,
    securityMode: SecurityMode.approvalRequired,
    pinRequired: false,
    wsUrl: wsUrl,
    status: RoomAnnounceStatus.open,
    protocolV: LancastConstants.protocolVersion,
  );
  await announcer.start(payload);

  stdout.writeln('Host up: $roomId @ $wsUrl');
  stdout.writeln('Auto-approve ON. Ctrl+C to stop.');

  server.onEnvelope = (peer, envelope) {
    if (envelope.type != EventType.joinRequest) {
      stdout.writeln('<< ${envelope.type}');
      return;
    }
    final req = JoinRequestPayload.fromJson(envelope.payload);
    stdout.writeln('JOIN_REQUEST from ${req.device.name} (${req.device.ip})');
    peer.deviceId = req.device.deviceId;
    final token = AccessToken(
      value: 'e2e-${DateTime.now().millisecondsSinceEpoch}',
      permission: LancastConstants.permissionScreenShare,
      expiresAt: DateTime.now().toUtc().add(LancastConstants.tokenTtl),
    );
    peer.send(
      Envelope.create(
        type: EventType.joinApproved,
        roomId: roomId,
        payload: JoinApprovedPayload(
          requestId: req.requestId,
          deviceId: req.device.deviceId,
          token: token,
        ).toJson(),
      ),
    );
    stdout.writeln('>> JOIN_APPROVED ${req.device.name} token=${redactToken(token.value)}');
  };

  // Keep process alive.
  final completer = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('Stopping…');
    await announcer.stop();
    await server.dispose();
    completer.complete();
  });
  await completer.future;
}
