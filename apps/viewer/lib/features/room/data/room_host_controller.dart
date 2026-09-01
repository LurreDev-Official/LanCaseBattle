import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:lancast_signaling/lancast_signaling.dart';
import 'package:lancast_viewer/features/approval/domain/pending_join_request.dart';
import 'package:lancast_viewer/features/devices/domain/connected_device.dart';
import 'package:lancast_viewer/features/room/domain/active_room.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';
import 'package:logger/logger.dart';

final roomHostProvider =
    StateNotifierProvider<RoomHostController, RoomHostState>((ref) {
  return RoomHostController();
});

class RoomHostState {
  const RoomHostState({
    this.room,
    this.error,
    this.isStarting = false,
    this.peerCount = 0,
    this.pendingRequests = const [],
    this.devices = const [],
    this.layout = GridLayoutMode.auto,
    this.qualityId = '720p30',
    this.lastEvent,
    this.renderTick = 0,
  });

  final ActiveRoom? room;
  final String? error;
  final bool isStarting;
  final int peerCount;
  final List<PendingJoinRequest> pendingRequests;
  final List<ConnectedDevice> devices;
  final GridLayoutMode layout;
  final String qualityId;
  final String? lastEvent;
  final int renderTick;

  bool get isRunning => room != null;
  int get pendingCount => pendingRequests.length;

  RoomHostState copyWith({
    ActiveRoom? room,
    String? error,
    bool? isStarting,
    int? peerCount,
    List<PendingJoinRequest>? pendingRequests,
    List<ConnectedDevice>? devices,
    GridLayoutMode? layout,
    String? qualityId,
    String? lastEvent,
    int? renderTick,
    bool clearRoom = false,
    bool clearError = false,
  }) {
    return RoomHostState(
      room: clearRoom ? null : (room ?? this.room),
      error: clearError ? null : (error ?? this.error),
      isStarting: isStarting ?? this.isStarting,
      peerCount: peerCount ?? this.peerCount,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      devices: devices ?? this.devices,
      layout: layout ?? this.layout,
      qualityId: qualityId ?? this.qualityId,
      lastEvent: lastEvent ?? this.lastEvent,
      renderTick: renderTick ?? this.renderTick,
    );
  }
}

class _LiveRequest {
  _LiveRequest({
    required this.view,
    required this.peer,
    required this.timer,
  });

  final PendingJoinRequest view;
  final SignalingPeer peer;
  final Timer timer;
}

class _DeviceRecord {
  _DeviceRecord({
    required this.device,
    required this.token,
    required this.peer,
  });

  ConnectedDevice device;
  AccessToken token;
  SignalingPeer peer;
  bool revoked = false;
  DateTime lastHeartbeat = DateTime.now();
  ViewerPeer? rtc;
}

class RoomHostController extends StateNotifier<RoomHostState> {
  RoomHostController({
    DiscoveryAnnouncer? announcer,
    SignalingServer? server,
    Logger? logger,
  })  : _announcer = announcer ?? DiscoveryAnnouncer(),
        _server = server ?? SignalingServer(),
        _log = logger ?? Logger(),
        super(const RoomHostState()) {
    _server.onEnvelope = _onEnvelope;
    _server.onPeerClosed = _onPeerClosed;
    _server.onPeersChanged = () {
      state = state.copyWith(peerCount: _server.peerCount);
    };
  }

  final DiscoveryAnnouncer _announcer;
  final SignalingServer _server;
  final Logger _log;
  final _live = <String, _LiveRequest>{};
  final _devices = <String, _DeviceRecord>{};
  final _rng = Random.secure();
  Timer? _heartbeatTimer;

  RTCVideoRenderer? rendererFor(String deviceId) =>
      _devices[deviceId]?.rtc?.renderer;

  Future<void> setAllRemoteAudioEnabled(bool enabled) async {
    for (final record in _devices.values) {
      await record.rtc?.setRemoteAudioEnabled(enabled);
    }
  }

  Future<ActiveRoom> createRoom({
    required String name,
    required SecurityMode securityMode,
    String? pin,
  }) async {
    state = state.copyWith(isStarting: true, clearError: true);
    try {
      await stopRoom();

      final lanIp = await resolveLanIpv4();
      final hostIp = lanIp?.address ?? '127.0.0.1';
      final ownerName = await resolveOwnerName();
      final roomId = generateRoomId(name);
      final trimmedPin = pin?.trim();
      final pinRequired = trimmedPin != null && trimmedPin.isNotEmpty;

      await _server.start();
      final port = _server.boundPort ?? LancastConstants.signalingPort;
      final wsUrl = 'ws://$hostIp:$port';

      final room = ActiveRoom(
        roomId: roomId,
        name: name.trim(),
        ownerName: ownerName,
        securityMode: securityMode,
        pinRequired: pinRequired,
        wsUrl: wsUrl,
        lanIp: hostIp,
        signalingPort: port,
        pinHash: pinRequired ? hashPin(trimmedPin) : null,
      );

      await _announcer.start(room.toAnnouncePayload());
      _startHeartbeatWatch();

      state = RoomHostState(
        room: room,
        peerCount: _server.peerCount,
        qualityId: state.qualityId,
        layout: state.layout,
      );
      _log.i('Room host started ${room.roomId} @ ${room.wsUrl}');
      return room;
    } catch (e, st) {
      _log.e('Failed to create room', error: e, stackTrace: st);
      state = state.copyWith(
        isStarting: false,
        error: e.toString(),
        clearRoom: true,
      );
      rethrow;
    }
  }

  Future<void> stopRoom() async {
    final room = state.room;
    if (room != null) {
      _server.broadcast(
        Envelope.create(
          type: EventType.roomClosed,
          roomId: room.roomId,
          payload: const RoomClosedPayload(reason: 'admin_closed').toJson(),
        ),
      );
    }

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    for (final live in _live.values) {
      live.timer.cancel();
    }
    _live.clear();

    for (final record in _devices.values) {
      await record.rtc?.dispose();
    }
    _devices.clear();

    await _announcer.stop();
    await _server.stop();
    state = const RoomHostState();
  }

  void setLayout(GridLayoutMode mode) {
    state = state.copyWith(layout: mode);
  }

  void setQuality(String qualityId) {
    state = state.copyWith(qualityId: qualityId);
  }

  void approve(String requestId) {
    final live = _live.remove(requestId);
    if (live == null) return;
    live.timer.cancel();
    final room = state.room;
    if (room == null) return;

    final token = _issueToken();
    _registerDevice(
      peer: live.peer,
      view: live.view,
      token: token,
    );

    live.peer.send(
      Envelope.create(
        type: EventType.joinApproved,
        roomId: room.roomId,
        payload: JoinApprovedPayload(
          requestId: requestId,
          deviceId: live.view.deviceId,
          token: token,
        ).toJson(),
      ),
    );

    _publishState(lastEvent: 'Approved ${live.view.deviceName}');
    _log.i('Approved ${live.view.deviceName} token=${redactToken(token.value)}');
  }

  void reject(String requestId, {String reason = 'Admin denied'}) {
    final live = _live.remove(requestId);
    if (live == null) return;
    live.timer.cancel();

    final room = state.room;
    if (room != null) {
      live.peer.send(
        Envelope.create(
          type: EventType.joinRejected,
          roomId: room.roomId,
          payload: JoinRejectedPayload(
            requestId: requestId,
            deviceId: live.view.deviceId,
            reason: reason,
          ).toJson(),
        ),
      );
    }

    _publishState(lastEvent: 'Rejected ${live.view.deviceName}');
    _log.i('Rejected ${live.view.deviceName}: $reason');
  }

  Future<void> revokeDevice(String deviceId) async {
    final record = _devices.remove(deviceId);
    if (record == null) return;
    record.revoked = true;
    final room = state.room;
    if (room != null) {
      record.peer.send(
        Envelope.create(
          type: EventType.accessRevoked,
          roomId: room.roomId,
          payload: AccessRevokedPayload(
            deviceId: deviceId,
            reason: 'Removed by admin',
          ).toJson(),
        ),
      );
    }
    await record.rtc?.dispose();
    try {
      await record.peer.close();
    } catch (_) {}
    _publishState(lastEvent: 'Revoked ${record.device.name}');
    _log.i('ACCESS_REVOKED ${record.device.name}');
  }

  void _onEnvelope(SignalingPeer peer, Envelope envelope) {
    final room = state.room;
    if (room == null) return;
    if (envelope.roomId != null &&
        envelope.roomId!.isNotEmpty &&
        envelope.roomId != room.roomId) {
      return;
    }

    switch (envelope.type) {
      case EventType.joinRequest:
        _handleJoinRequest(peer, envelope);
      case EventType.deviceState:
        _handleDeviceState(peer, envelope);
      case EventType.deviceLeft:
        unawaited(_handleDeviceLeft(peer, envelope));
      case EventType.heartbeat:
        _handleHeartbeat(peer, envelope);
      case EventType.signalOffer:
        unawaited(_handleOffer(peer, envelope));
      case EventType.signalAnswer:
        // Viewer does not expect answers in MVP (sender offers).
        break;
      case EventType.signalIce:
        unawaited(_handleIce(peer, envelope));
      default:
        break;
    }
  }

  void _handleJoinRequest(SignalingPeer peer, Envelope envelope) {
    final room = state.room;
    if (room == null) return;

    final payload = JoinRequestPayload.fromJson(envelope.payload);
    if (payload.requestId.isEmpty || payload.device.deviceId.isEmpty) return;

    if (room.pinRequired) {
      final pin = payload.pin?.trim() ?? '';
      if (pin.isEmpty ||
          room.pinHash == null ||
          !verifyPin(pin: pin, pinHash: room.pinHash!)) {
        peer.send(
          Envelope.create(
            type: EventType.joinRejected,
            roomId: room.roomId,
            payload: JoinRejectedPayload(
              requestId: payload.requestId,
              deviceId: payload.device.deviceId,
              reason: 'Invalid PIN',
            ).toJson(),
          ),
        );
        _log.w('Join rejected (bad PIN) ${payload.device.name}');
        return;
      }
    }

    // Resume token auto-approve.
    final resume = payload.resumeToken;
    final existing = _devices[payload.device.deviceId];
    if (resume != null &&
        existing != null &&
        !existing.revoked &&
        existing.token.value == resume &&
        !existing.token.isExpired) {
      existing.peer = peer;
      peer.deviceId = payload.device.deviceId;
      existing.device = existing.device.copyWith(
        name: payload.device.name,
        ip: payload.device.ip,
        lastSeen: DateTime.now(),
      );
      peer.send(
        Envelope.create(
          type: EventType.joinApproved,
          roomId: room.roomId,
          payload: JoinApprovedPayload(
            requestId: payload.requestId,
            deviceId: payload.device.deviceId,
            token: existing.token,
          ).toJson(),
        ),
      );
      _publishState(lastEvent: 'Resumed ${payload.device.name}');
      _log.i('Auto-approved resume ${payload.device.name}');
      return;
    }

    if (_devices.length >= LancastConstants.maxActiveStreams &&
        !_devices.containsKey(payload.device.deviceId)) {
      peer.send(
        Envelope.create(
          type: EventType.joinRejected,
          roomId: room.roomId,
          payload: JoinRejectedPayload(
            requestId: payload.requestId,
            deviceId: payload.device.deviceId,
            reason: 'Room full (max ${LancastConstants.maxActiveStreams})',
          ).toJson(),
        ),
      );
      return;
    }

    final existingPending = _live.entries
        .where((e) => e.value.view.deviceId == payload.device.deviceId)
        .map((e) => e.key)
        .toList();
    for (final id in existingPending) {
      _live.remove(id)?.timer.cancel();
    }

    peer.deviceId = payload.device.deviceId;
    final view = PendingJoinRequest(
      requestId: payload.requestId,
      deviceId: payload.device.deviceId,
      deviceName: payload.device.name,
      os: payload.device.os,
      username: payload.device.username,
      ip: payload.device.ip,
      createdAt: DateTime.now(),
    );

    final timer = Timer(LancastConstants.joinRequestTimeout, () {
      if (!_live.containsKey(payload.requestId)) return;
      reject(payload.requestId, reason: 'timeout');
    });

    _live[payload.requestId] = _LiveRequest(
      view: view,
      peer: peer,
      timer: timer,
    );
    _publishState(lastEvent: 'Join request: ${view.deviceName}');
    _log.i('JOIN_REQUEST ${view.deviceName} ip=${view.ip}');
  }

  void _registerDevice({
    required SignalingPeer peer,
    required PendingJoinRequest view,
    required AccessToken token,
  }) {
    peer.deviceId = view.deviceId;
    _devices[view.deviceId] = _DeviceRecord(
      device: ConnectedDevice(
        deviceId: view.deviceId,
        name: view.deviceName,
        os: view.os,
        ip: view.ip,
        username: view.username,
        streamState: DeviceStreamState.idle,
        lastSeen: DateTime.now(),
      ),
      token: token,
      peer: peer,
    );
  }

  bool _isAuthorized(SignalingPeer peer, String deviceId) {
    final record = _devices[deviceId];
    if (record == null || record.revoked) return false;
    if (record.token.isExpired) return false;
    if (peer.deviceId != null && peer.deviceId != deviceId) return false;
    return true;
  }

  Future<void> _handleOffer(SignalingPeer peer, Envelope envelope) async {
    final payload = SignalSdpPayload.fromJson(envelope.payload);
    final room = state.room;
    if (room == null) return;
    if (!_isAuthorized(peer, payload.deviceId)) {
      _log.w('Reject SIGNAL_OFFER unauthorized ${payload.deviceId}');
      return;
    }
    if (payload.sdp.isEmpty) return;

    final record = _devices[payload.deviceId]!;
    await record.rtc?.dispose();
    final rtc = ViewerPeer(
      deviceId: payload.deviceId,
      onIce: (candidate) {
        peer.send(
          Envelope.create(
            type: EventType.signalIce,
            roomId: room.roomId,
            payload: SignalIcePayload(
              deviceId: payload.deviceId,
              candidate: candidate.toMap(),
            ).toJson(),
          ),
        );
      },
      onTrack: (_) {
        record.device = record.device.copyWith(
          hasRemoteVideo: true,
          streamState: DeviceStreamState.streaming,
          lastSeen: DateTime.now(),
        );
        _publishState();
      },
    );
    await rtc.init();
    record.rtc = rtc;

    final answer = await rtc.acceptOffer(
      RTCSessionDescription(payload.sdp, payload.type),
    );
    peer.send(
      Envelope.create(
        type: EventType.signalAnswer,
        roomId: room.roomId,
        payload: SignalSdpPayload(
          deviceId: payload.deviceId,
          sdp: answer.sdp ?? '',
          type: answer.type ?? 'answer',
        ).toJson(),
      ),
    );
    _publishState(lastEvent: 'Stream from ${record.device.name}');
  }

  Future<void> _handleIce(SignalingPeer peer, Envelope envelope) async {
    final payload = SignalIcePayload.fromJson(envelope.payload);
    if (!_isAuthorized(peer, payload.deviceId)) return;
    final rtc = _devices[payload.deviceId]?.rtc;
    if (rtc == null) return;
    final map = payload.candidate;
    await rtc.addIce(
      RTCIceCandidate(
        map['candidate'] as String?,
        map['sdpMid'] as String?,
        map['sdpMLineIndex'] as int?,
      ),
    );
  }

  void _handleDeviceState(SignalingPeer peer, Envelope envelope) {
    final payload = DeviceStatePayload.fromJson(envelope.payload);
    if (!_isAuthorized(peer, payload.deviceId)) return;
    final record = _devices[payload.deviceId];
    if (record == null) return;
    record.device = record.device.copyWith(
      streamState: payload.state,
      lastSeen: DateTime.now(),
    );
    record.lastHeartbeat = DateTime.now();
    _publishState();
  }

  Future<void> _handleDeviceLeft(SignalingPeer peer, Envelope envelope) async {
    final payload = DeviceLeftPayload.fromJson(envelope.payload);
    final record = _devices.remove(payload.deviceId);
    await record?.rtc?.dispose();
    _publishState(lastEvent: '${payload.deviceId} left');
  }

  void _handleHeartbeat(SignalingPeer peer, Envelope envelope) {
    final payload = HeartbeatPayload.fromJson(envelope.payload);
    final record = _devices[payload.deviceId];
    if (record == null) return;
    record.lastHeartbeat = DateTime.now();
    record.device = record.device.copyWith(lastSeen: DateTime.now());
    // Reply heartbeat.
    final room = state.room;
    if (room != null) {
      peer.send(
        Envelope.create(
          type: EventType.heartbeat,
          roomId: room.roomId,
          payload: HeartbeatPayload(
            deviceId: payload.deviceId,
            seq: payload.seq,
          ).toJson(),
        ),
      );
    }
  }

  void _startHeartbeatWatch() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(LancastConstants.heartbeatInterval, (_) {
      final cutoff = DateTime.now().subtract(
        LancastConstants.heartbeatInterval * LancastConstants.heartbeatMissLimit,
      );
      final stale = _devices.entries
          .where((e) => e.value.lastHeartbeat.isBefore(cutoff))
          .map((e) => e.key)
          .toList();
      for (final id in stale) {
        _log.w('Stale device $id — revoking session');
        unawaited(revokeDevice(id));
      }
    });
  }

  void _onPeerClosed(SignalingPeer peer) {
    final dropPending = _live.entries
        .where((e) => identical(e.value.peer, peer))
        .map((e) => e.key)
        .toList();
    for (final id in dropPending) {
      _live.remove(id)?.timer.cancel();
    }

    // Keep token vault for resume; only tear down media + mark idle.
    for (final record in _devices.values) {
      if (!identical(record.peer, peer)) continue;
      unawaited(record.rtc?.dispose() ?? Future.value());
      record.rtc = null;
      record.device = record.device.copyWith(
        streamState: DeviceStreamState.idle,
        hasRemoteVideo: false,
        lastSeen: DateTime.now(),
      );
    }

    if (dropPending.isNotEmpty) {
      _publishState();
    } else {
      _publishState();
    }
  }

  void _publishState({String? lastEvent}) {
    state = state.copyWith(
      pendingRequests: _live.values.map((e) => e.view).toList(growable: false),
      devices: _devices.values.map((e) => e.device).toList(growable: false),
      peerCount: _server.peerCount,
      lastEvent: lastEvent,
      renderTick: state.renderTick + 1,
    );
  }

  AccessToken _issueToken() {
    final bytes = List<int>.generate(24, (_) => _rng.nextInt(256));
    return AccessToken(
      value: base64UrlEncode(bytes).replaceAll('=', ''),
      permission: LancastConstants.permissionScreenShare,
      expiresAt: DateTime.now().toUtc().add(LancastConstants.tokenTtl),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    for (final live in _live.values) {
      live.timer.cancel();
    }
    _live.clear();
    for (final record in _devices.values) {
      unawaited(record.rtc?.dispose() ?? Future.value());
    }
    _devices.clear();
    unawaited(_announcer.stop());
    unawaited(_server.dispose());
    super.dispose();
  }
}
