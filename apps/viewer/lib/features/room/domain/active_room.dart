import 'package:lancast_core/lancast_core.dart';

class ActiveRoom {
  const ActiveRoom({
    required this.roomId,
    required this.name,
    required this.ownerName,
    required this.securityMode,
    required this.pinRequired,
    required this.wsUrl,
    required this.lanIp,
    required this.signalingPort,
    this.pinHash,
  });

  final String roomId;
  final String name;
  final String ownerName;
  final SecurityMode securityMode;
  final bool pinRequired;
  final String wsUrl;
  final String lanIp;
  final int signalingPort;

  /// SHA-256 hex; never store plaintext PIN.
  final String? pinHash;

  RoomAnnouncePayload toAnnouncePayload() {
    return RoomAnnouncePayload(
      roomId: roomId,
      name: name,
      ownerName: ownerName,
      securityMode: securityMode,
      pinRequired: pinRequired,
      wsUrl: wsUrl,
      status: RoomAnnounceStatus.open,
      protocolV: LancastConstants.protocolVersion,
    );
  }
}
