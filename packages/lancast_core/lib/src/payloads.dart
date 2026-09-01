import 'package:lancast_core/src/enums.dart';

class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.name,
    required this.os,
    this.username,
    this.osVersion,
    this.ip,
    this.appVersion,
  });

  final String deviceId;
  final String name;
  final String os;
  final String? username;
  final String? osVersion;
  final String? ip;
  final String? appVersion;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      os: json['os'] as String? ?? '',
      username: json['username'] as String?,
      osVersion: json['os_version'] as String?,
      ip: json['ip'] as String?,
      appVersion: json['app_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'name': name,
        'os': os,
        if (username != null) 'username': username,
        if (osVersion != null) 'os_version': osVersion,
        if (ip != null) 'ip': ip,
        if (appVersion != null) 'app_version': appVersion,
      };
}

class AccessToken {
  const AccessToken({
    required this.value,
    required this.permission,
    required this.expiresAt,
  });

  final String value;
  final String permission;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      value: json['value'] as String? ?? '',
      permission: json['permission'] as String? ?? 'screen_share',
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'permission': permission,
        'expires_at': expiresAt.toUtc().toIso8601String(),
      };
}

class RoomAnnouncePayload {
  const RoomAnnouncePayload({
    required this.roomId,
    required this.name,
    required this.ownerName,
    required this.securityMode,
    required this.pinRequired,
    required this.wsUrl,
    required this.status,
    required this.protocolV,
  });

  final String roomId;
  final String name;
  final String ownerName;
  final SecurityMode securityMode;
  final bool pinRequired;
  final String wsUrl;
  final RoomAnnounceStatus status;
  final int protocolV;

  factory RoomAnnouncePayload.fromJson(Map<String, dynamic> json) {
    return RoomAnnouncePayload(
      roomId: json['room_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      securityMode: SecurityMode.fromWire(
        json['security_mode'] as String? ?? 'approval_required',
      ),
      pinRequired: json['pin_required'] as bool? ?? false,
      wsUrl: json['ws_url'] as String? ?? '',
      status: RoomAnnounceStatus.fromWire(json['status'] as String? ?? 'open'),
      protocolV: (json['protocol_v'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'name': name,
        'owner_name': ownerName,
        'security_mode': securityMode.wire,
        'pin_required': pinRequired,
        'ws_url': wsUrl,
        'status': status.name,
        'protocol_v': protocolV,
      };
}

class JoinRequestPayload {
  const JoinRequestPayload({
    required this.requestId,
    required this.device,
    this.pin,
    this.resumeToken,
  });

  final String requestId;
  final DeviceInfo device;
  final String? pin;
  final String? resumeToken;

  factory JoinRequestPayload.fromJson(Map<String, dynamic> json) {
    final deviceRaw = json['device'];
    return JoinRequestPayload(
      requestId: json['request_id'] as String? ?? '',
      device: deviceRaw is Map<String, dynamic>
          ? DeviceInfo.fromJson(deviceRaw)
          : const DeviceInfo(deviceId: '', name: '', os: ''),
      pin: json['pin'] as String?,
      resumeToken: json['resume_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'device': device.toJson(),
        'pin': pin,
        'resume_token': resumeToken,
      };
}

class JoinApprovedPayload {
  const JoinApprovedPayload({
    required this.requestId,
    required this.deviceId,
    required this.token,
  });

  final String requestId;
  final String deviceId;
  final AccessToken token;

  factory JoinApprovedPayload.fromJson(Map<String, dynamic> json) {
    final tokenRaw = json['token'];
    return JoinApprovedPayload(
      requestId: json['request_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      token: tokenRaw is Map<String, dynamic>
          ? AccessToken.fromJson(tokenRaw)
          : AccessToken(
              value: '',
              permission: 'screen_share',
              expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'device_id': deviceId,
        'token': token.toJson(),
      };
}

class JoinRejectedPayload {
  const JoinRejectedPayload({
    required this.requestId,
    required this.deviceId,
    required this.reason,
  });

  final String requestId;
  final String deviceId;
  final String reason;

  factory JoinRejectedPayload.fromJson(Map<String, dynamic> json) {
    return JoinRejectedPayload(
      requestId: json['request_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'rejected',
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'device_id': deviceId,
        'reason': reason,
      };
}

class AccessRevokedPayload {
  const AccessRevokedPayload({
    required this.deviceId,
    required this.reason,
  });

  final String deviceId;
  final String reason;

  factory AccessRevokedPayload.fromJson(Map<String, dynamic> json) {
    return AccessRevokedPayload(
      deviceId: json['device_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'revoked',
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'reason': reason,
      };
}

class DeviceLeftPayload {
  const DeviceLeftPayload({
    required this.deviceId,
    required this.reason,
  });

  final String deviceId;
  final String reason;

  factory DeviceLeftPayload.fromJson(Map<String, dynamic> json) {
    return DeviceLeftPayload(
      deviceId: json['device_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'user_leave',
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'reason': reason,
      };
}

class DeviceStatePayload {
  const DeviceStatePayload({
    required this.deviceId,
    required this.state,
  });

  final String deviceId;
  final DeviceStreamState state;

  factory DeviceStatePayload.fromJson(Map<String, dynamic> json) {
    return DeviceStatePayload(
      deviceId: json['device_id'] as String? ?? '',
      state: DeviceStreamState.fromWire(json['state'] as String? ?? 'idle'),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'state': state.name,
      };
}

class SignalSdpPayload {
  const SignalSdpPayload({
    required this.deviceId,
    required this.sdp,
    required this.type,
  });

  final String deviceId;
  final String sdp;
  final String type;

  factory SignalSdpPayload.fromJson(Map<String, dynamic> json) {
    return SignalSdpPayload(
      deviceId: json['device_id'] as String? ?? '',
      sdp: json['sdp'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'sdp': sdp,
        'type': type,
      };
}

class SignalIcePayload {
  const SignalIcePayload({
    required this.deviceId,
    required this.candidate,
  });

  final String deviceId;
  final Map<String, dynamic> candidate;

  factory SignalIcePayload.fromJson(Map<String, dynamic> json) {
    final raw = json['candidate'];
    return SignalIcePayload(
      deviceId: json['device_id'] as String? ?? '',
      candidate: raw is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'candidate': candidate,
      };
}

class RoomClosedPayload {
  const RoomClosedPayload({required this.reason});

  final String reason;

  factory RoomClosedPayload.fromJson(Map<String, dynamic> json) {
    return RoomClosedPayload(
      reason: json['reason'] as String? ?? 'admin_closed',
    );
  }

  Map<String, dynamic> toJson() => {'reason': reason};
}

class HeartbeatPayload {
  const HeartbeatPayload({
    required this.deviceId,
    required this.seq,
  });

  final String deviceId;
  final int seq;

  factory HeartbeatPayload.fromJson(Map<String, dynamic> json) {
    return HeartbeatPayload(
      deviceId: json['device_id'] as String? ?? '',
      seq: (json['seq'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'seq': seq,
      };
}

class ErrorPayload {
  const ErrorPayload({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory ErrorPayload.fromJson(Map<String, dynamic> json) {
    return ErrorPayload(
      code: json['code'] as String? ?? 'ERROR',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };
}
