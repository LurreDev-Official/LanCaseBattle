import 'package:lancast_core/src/envelope.dart';
import 'package:lancast_core/src/event_type.dart';
import 'package:lancast_core/src/payloads.dart';

/// Typed decode of [Envelope.payload] by [Envelope.type].
Object? parsePayload(Envelope envelope) {
  final p = envelope.payload;
  switch (envelope.type) {
    case EventType.roomAnnounce:
      return RoomAnnouncePayload.fromJson(p);
    case EventType.joinRequest:
      return JoinRequestPayload.fromJson(p);
    case EventType.joinApproved:
      return JoinApprovedPayload.fromJson(p);
    case EventType.joinRejected:
      return JoinRejectedPayload.fromJson(p);
    case EventType.accessRevoked:
      return AccessRevokedPayload.fromJson(p);
    case EventType.deviceLeft:
      return DeviceLeftPayload.fromJson(p);
    case EventType.deviceState:
      return DeviceStatePayload.fromJson(p);
    case EventType.signalOffer:
    case EventType.signalAnswer:
      return SignalSdpPayload.fromJson(p);
    case EventType.signalIce:
      return SignalIcePayload.fromJson(p);
    case EventType.roomClosed:
      return RoomClosedPayload.fromJson(p);
    case EventType.heartbeat:
      return HeartbeatPayload.fromJson(p);
    case EventType.error:
      return ErrorPayload.fromJson(p);
    default:
      return null;
  }
}
