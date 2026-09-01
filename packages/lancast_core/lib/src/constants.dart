/// Default LAN ports and protocol constants.
abstract final class LancastConstants {
  static const int protocolVersion = 1;
  static const String mdnsServiceType = '_lancast._tcp';
  static const int signalingPort = 17890;
  static const int udpBroadcastPort = 17891;
  static const Duration tokenTtl = Duration(hours: 24);
  static const Duration joinRequestTimeout = Duration(minutes: 2);
  static const Duration heartbeatInterval = Duration(seconds: 10);
  static const int heartbeatMissLimit = 3;
  static const int maxActiveStreams = 6;
  static const String permissionScreenShare = 'screen_share';
}
