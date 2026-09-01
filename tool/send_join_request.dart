/// Discovers a LanCast room on LAN and sends JOIN_REQUEST.
/// Usage: dart run tool/send_join_request.dart
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:lancast_signaling/lancast_signaling.dart';

Future<void> main() async {
  stdout.writeln('Scanning for rooms (8s)…');
  final scanner = DiscoveryScanner();
  await scanner.start();

  RoomAnnouncePayload? room;
  try {
    room = await scanner.rooms$
        .expand((rooms) => rooms)
        .first
        .timeout(const Duration(seconds: 8));
  } on TimeoutException {
    stdout.writeln('FAIL: no room found. Create a room in Viewer first.');
    await scanner.dispose();
    exit(1);
  }

  stdout.writeln('Found: ${room.name} (${room.roomId}) @ ${room.wsUrl}');
  await scanner.stop();

  final client = SignalingClient();
  final approved = Completer<JoinApprovedPayload>();
  final rejected = Completer<JoinRejectedPayload>();

  client.envelopes$.listen((env) {
    stdout.writeln('<< ${env.type}');
    if (env.type == EventType.joinApproved && !approved.isCompleted) {
      approved.complete(JoinApprovedPayload.fromJson(env.payload));
    }
    if (env.type == EventType.joinRejected && !rejected.isCompleted) {
      rejected.complete(JoinRejectedPayload.fromJson(env.payload));
    }
  });

  await client.connect(Uri.parse(room.wsUrl));
  stdout.writeln('WS connected');

  final lan = await resolveLanIpv4();
  final id = _id();
  final requestId = _id();
  final payload = JoinRequestPayload(
    requestId: requestId,
    device: DeviceInfo(
      deviceId: id,
      name: 'AutoJoin-Tester',
      username: Platform.environment['USER'] ?? 'tester',
      os: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      ip: lan?.address ?? '127.0.0.1',
      appVersion: '0.1.0-test',
    ),
  );

  client.send(
    Envelope.create(
      type: EventType.joinRequest,
      roomId: room.roomId,
      payload: payload.toJson(),
    ),
  );
  stdout.writeln('>> JOIN_REQUEST sent as AutoJoin-Tester');
  stdout.writeln('Approve or Reject it in the Viewer dashboard…');

  final result = await Future.any([
    approved.future.then((v) => ('approved', v)),
    rejected.future.then((v) => ('rejected', v)),
    Future<void>.delayed(const Duration(seconds: 60)).then((_) => ('timeout', null)),
  ]);

  switch (result.$1) {
    case 'approved':
      final token = (result.$2 as JoinApprovedPayload).token;
      stdout.writeln('OK: JOIN_APPROVED token=${redactToken(token.value)}');
    case 'rejected':
      final reason = (result.$2 as JoinRejectedPayload).reason;
      stdout.writeln('OK: JOIN_REJECTED reason=$reason');
    default:
      stdout.writeln('FAIL: no response in 60s (request may still be pending in Viewer)');
  }

  await client.dispose();
  await scanner.dispose();
}

String _id() {
  final r = Random.secure();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}'
      '${List.generate(3, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
