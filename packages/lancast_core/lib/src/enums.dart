enum AppRole {
  roomAdmin,
  approvedSender,
  guest,
}

enum SecurityMode {
  approvalRequired('approval_required'),
  pinRequired('pin_required'),
  trustedDeviceOnly('trusted_device_only');

  const SecurityMode(this.wire);
  final String wire;

  static SecurityMode fromWire(String value) {
    return SecurityMode.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => SecurityMode.approvalRequired,
    );
  }
}

enum SenderStatus {
  discovering,
  requesting,
  waitingApproval,
  approved,
  connecting,
  connected,
  streaming,
  idle,
  rejected,
  disconnected,
}

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  expired,
}

enum DeviceStreamState {
  idle,
  streaming,
  paused;

  static DeviceStreamState fromWire(String value) {
    return DeviceStreamState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceStreamState.idle,
    );
  }
}

enum RoomAnnounceStatus {
  open,
  closed;

  static RoomAnnounceStatus fromWire(String value) {
    return RoomAnnounceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoomAnnounceStatus.open,
    );
  }
}
