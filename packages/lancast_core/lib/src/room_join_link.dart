import 'package:lancast_core/src/enums.dart';
import 'package:lancast_core/src/payloads.dart';

/// LAN join invite encoded as `lancast://join?...`
///
/// Example:
/// `lancast://join?room_id=ARENA-1&name=OPEN+CUP&ws_url=ws%3A%2F%2F192.168.1.10%3A17890&owner_name=Judge-PC&security_mode=approval_required&pin_required=0&protocol_v=1`
abstract final class RoomJoinLink {
  static const scheme = 'lancast';
  static const host = 'join';

  /// Builds a shareable invite URI from a room announce payload.
  static Uri encode(RoomAnnouncePayload room) {
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'room_id': room.roomId,
        'name': room.name,
        'ws_url': room.wsUrl,
        'owner_name': room.ownerName,
        'security_mode': room.securityMode.wire,
        'pin_required': room.pinRequired ? '1' : '0',
        'protocol_v': '${room.protocolV}',
        'status': room.status.name,
      },
    );
  }

  static String encodeString(RoomAnnouncePayload room) =>
      encode(room).toString();

  /// Parses invite text (full URI, or pasted query). Returns null if invalid.
  static RoomAnnouncePayload? tryDecode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    // Allow bare query paste: room_id=...&ws_url=...
    if (!uri.hasScheme &&
        trimmed.contains('room_id=') &&
        trimmed.contains('ws_url=')) {
      uri = Uri.parse('$scheme://$host?$trimmed');
    }

    if (uri.scheme != scheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      return null;
    }

    // Short form: lancast://join/ROOM_ID@host:port
    if (uri.scheme == scheme &&
        uri.host == host &&
        uri.pathSegments.isNotEmpty) {
      final token = uri.pathSegments.first;
      final at = token.split('@');
      if (at.length == 2 && at[0].isNotEmpty && at[1].isNotEmpty) {
        final roomId = at[0];
        final endpoint = at[1];
        final ws = endpoint.startsWith('ws') ? endpoint : 'ws://$endpoint';
        return RoomAnnouncePayload(
          roomId: roomId,
          name: roomId,
          ownerName: 'Host',
          securityMode: SecurityMode.approvalRequired,
          pinRequired: false,
          wsUrl: ws,
          status: RoomAnnounceStatus.open,
          protocolV: 1,
        );
      }
    }

    if (uri.scheme == scheme && uri.host == host) {
      return _fromQuery(uri.queryParameters);
    }

    // https://lancast.local/join?... mirror
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host.contains('lancast') || uri.path.contains('join'))) {
      return _fromQuery(uri.queryParameters);
    }

    return null;
  }

  static RoomAnnouncePayload? _fromQuery(Map<String, String> q) {
    final roomId = q['room_id']?.trim() ?? '';
    final wsUrl = q['ws_url']?.trim() ?? '';
    if (roomId.isEmpty || wsUrl.isEmpty) return null;
    if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) return null;

    final pinRaw = (q['pin_required'] ?? '0').toLowerCase();
    final pinRequired = pinRaw == '1' || pinRaw == 'true' || pinRaw == 'yes';

    final name = q['name']?.trim();
    final owner = q['owner_name']?.trim();

    return RoomAnnouncePayload(
      roomId: roomId,
      name: (name != null && name.isNotEmpty) ? name : roomId,
      ownerName: (owner != null && owner.isNotEmpty) ? owner : 'Host',
      securityMode: SecurityMode.fromWire(
        q['security_mode'] ?? 'approval_required',
      ),
      pinRequired: pinRequired,
      wsUrl: wsUrl,
      status: RoomAnnounceStatus.fromWire(q['status'] ?? 'open'),
      protocolV: int.tryParse(q['protocol_v'] ?? '1') ?? 1,
    );
  }

  /// Human-friendly share text for chat / messages.
  static String shareMessage(RoomAnnouncePayload room) {
    final link = encodeString(room);
    return 'Join LanCast Arena room "${room.name}" (${room.roomId})\n'
        'Link: $link\n'
        'WS: ${room.wsUrl}\n'
        'Same LAN required · open in LanCast Sender → Join via Link';
  }
}
