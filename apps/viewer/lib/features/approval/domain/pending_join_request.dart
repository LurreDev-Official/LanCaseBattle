class PendingJoinRequest {
  const PendingJoinRequest({
    required this.requestId,
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.createdAt,
    this.username,
    this.ip,
  });

  final String requestId;
  final String deviceId;
  final String deviceName;
  final String os;
  final DateTime createdAt;
  final String? username;
  final String? ip;
}
