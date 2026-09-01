import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lancast_core/lancast_core.dart';

class StoredRoomToken {
  const StoredRoomToken({
    required this.roomId,
    required this.deviceId,
    required this.token,
    required this.deviceName,
    required this.wsUrl,
  });

  final String roomId;
  final String deviceId;
  final AccessToken token;
  final String deviceName;
  final String wsUrl;

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'device_id': deviceId,
        'device_name': deviceName,
        'ws_url': wsUrl,
        'token': token.toJson(),
      };

  factory StoredRoomToken.fromJson(Map<String, dynamic> json) {
    return StoredRoomToken(
      roomId: json['room_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? 'Laptop',
      wsUrl: json['ws_url'] as String? ?? '',
      token: AccessToken.fromJson(
        Map<String, dynamic>.from(json['token'] as Map? ?? {}),
      ),
    );
  }
}

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String roomId) => 'lancast.token.$roomId';

  Future<void> save(StoredRoomToken value) async {
    await _storage.write(key: _key(value.roomId), value: jsonEncode(value.toJson()));
  }

  Future<StoredRoomToken?> read(String roomId) async {
    final raw = await _storage.read(key: _key(roomId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return StoredRoomToken.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String roomId) async {
    await _storage.delete(key: _key(roomId));
  }
}
