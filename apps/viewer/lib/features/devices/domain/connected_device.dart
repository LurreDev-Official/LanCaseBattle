import 'package:lancast_core/lancast_core.dart';

class ConnectedDevice {
  const ConnectedDevice({
    required this.deviceId,
    required this.name,
    required this.os,
    required this.streamState,
    required this.lastSeen,
    this.ip,
    this.username,
    this.hasRemoteVideo = false,
  });

  final String deviceId;
  final String name;
  final String os;
  final String? ip;
  final String? username;
  final DeviceStreamState streamState;
  final DateTime lastSeen;
  final bool hasRemoteVideo;

  ConnectedDevice copyWith({
    String? name,
    DeviceStreamState? streamState,
    DateTime? lastSeen,
    bool? hasRemoteVideo,
    String? ip,
  }) {
    return ConnectedDevice(
      deviceId: deviceId,
      name: name ?? this.name,
      os: os,
      ip: ip ?? this.ip,
      username: username,
      streamState: streamState ?? this.streamState,
      lastSeen: lastSeen ?? this.lastSeen,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
    );
  }
}

enum GridLayoutMode { one, twoByTwo, auto }
