/// Canonical control-plane event type strings (PROTOCOL.md).
abstract final class EventType {
  static const roomAnnounce = 'ROOM_ANNOUNCE';
  static const joinRequest = 'JOIN_REQUEST';
  static const joinApproved = 'JOIN_APPROVED';
  static const joinRejected = 'JOIN_REJECTED';
  static const accessRevoked = 'ACCESS_REVOKED';
  static const deviceLeft = 'DEVICE_LEFT';
  static const deviceState = 'DEVICE_STATE';
  static const signalOffer = 'SIGNAL_OFFER';
  static const signalAnswer = 'SIGNAL_ANSWER';
  static const signalIce = 'SIGNAL_ICE';
  static const roomClosed = 'ROOM_CLOSED';
  static const heartbeat = 'HEARTBEAT';
  static const error = 'ERROR';

  static const Set<String> all = {
    roomAnnounce,
    joinRequest,
    joinApproved,
    joinRejected,
    accessRevoked,
    deviceLeft,
    deviceState,
    signalOffer,
    signalAnswer,
    signalIce,
    roomClosed,
    heartbeat,
    error,
  };

  static bool isKnown(String type) => all.contains(type);
}
