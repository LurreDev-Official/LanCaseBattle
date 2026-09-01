import 'dart:convert';

import 'package:lancast_core/src/constants.dart';
import 'package:lancast_core/src/event_type.dart';

/// Control-plane message envelope.
class Envelope {
  const Envelope({
    required this.v,
    required this.type,
    required this.roomId,
    required this.ts,
    required this.payload,
  });

  final int v;
  final String type;
  final String? roomId;
  final DateTime ts;
  final Map<String, dynamic> payload;

  bool get isSupportedVersion => v == LancastConstants.protocolVersion;
  bool get isKnownType => EventType.isKnown(type);

  factory Envelope.create({
    required String type,
    String? roomId,
    Map<String, dynamic> payload = const {},
    DateTime? ts,
    int v = LancastConstants.protocolVersion,
  }) {
    return Envelope(
      v: v,
      type: type,
      roomId: roomId,
      ts: ts ?? DateTime.now().toUtc(),
      payload: payload,
    );
  }

  factory Envelope.fromJson(Map<String, dynamic> json) {
    final rawTs = json['ts'];
    final DateTime ts;
    if (rawTs is String) {
      ts = DateTime.parse(rawTs);
    } else {
      ts = DateTime.now().toUtc();
    }

    final rawPayload = json['payload'];
    return Envelope(
      v: (json['v'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      roomId: json['room_id'] as String?,
      ts: ts,
      payload: rawPayload is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawPayload)
          : <String, dynamic>{},
    );
  }

  factory Envelope.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Envelope root must be a JSON object');
    }
    return Envelope.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'room_id': roomId,
        'ts': ts.toUtc().toIso8601String(),
        'payload': payload,
      };

  String toJsonString() => jsonEncode(toJson());

  Envelope copyWith({
    int? v,
    String? type,
    String? roomId,
    DateTime? ts,
    Map<String, dynamic>? payload,
  }) {
    return Envelope(
      v: v ?? this.v,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      ts: ts ?? this.ts,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Envelope &&
        other.v == v &&
        other.type == type &&
        other.roomId == roomId &&
        other.ts.toUtc() == ts.toUtc() &&
        _mapEquals(other.payload, payload);
  }

  @override
  int get hashCode => Object.hash(v, type, roomId, ts.toUtc(), payload.length);
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
