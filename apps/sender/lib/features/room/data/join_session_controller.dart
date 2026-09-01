import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_discovery/lancast_discovery.dart';
import 'package:lancast_sender/features/room/data/token_store.dart';
import 'package:lancast_signaling/lancast_signaling.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';
import 'package:logger/logger.dart';

final joinSessionProvider =
    StateNotifierProvider<JoinSessionController, JoinSessionState>((ref) {
  return JoinSessionController();
});

class JoinSessionState {
  const JoinSessionState({
    this.status = SenderStatus.discovering,
    this.room,
    this.deviceName = 'Laptop-Dev',
    this.requestId,
    this.deviceId,
    this.token,
    this.rejectReason,
    this.error,
    this.streamState = DeviceStreamState.idle,
    this.qualityId = '720p30',
  });

  final SenderStatus status;
  final RoomAnnouncePayload? room;
  final String deviceName;
  final String? requestId;
  final String? deviceId;
  final AccessToken? token;
  final String? rejectReason;
  final String? error;
  final DeviceStreamState streamState;
  final String qualityId;

  JoinSessionState copyWith({
    SenderStatus? status,
    RoomAnnouncePayload? room,
    String? deviceName,
    String? requestId,
    String? deviceId,
    AccessToken? token,
    String? rejectReason,
    String? error,
    DeviceStreamState? streamState,
    String? qualityId,
    bool clearRoom = false,
    bool clearToken = false,
    bool clearReject = false,
    bool clearError = false,
  }) {
    return JoinSessionState(
      status: status ?? this.status,
      room: clearRoom ? null : (room ?? this.room),
      deviceName: deviceName ?? this.deviceName,
      requestId: requestId ?? this.requestId,
      deviceId: deviceId ?? this.deviceId,
      token: clearToken ? null : (token ?? this.token),
      rejectReason: clearReject ? null : (rejectReason ?? this.rejectReason),
      error: clearError ? null : (error ?? this.error),
      streamState: streamState ?? this.streamState,
      qualityId: qualityId ?? this.qualityId,
    );
  }
}

class JoinSessionController extends StateNotifier<JoinSessionState> {
  JoinSessionController({
    SignalingClient? client,
    TokenStore? tokenStore,
    Logger? logger,
  })  : _client = client ?? SignalingClient(),
        _tokens = tokenStore ?? TokenStore(),
        _log = logger ?? Logger(),
        super(JoinSessionState(deviceId: _newId())) {
    _sub = _client.envelopes$.listen(_onEnvelope);
  }

  final SignalingClient _client;
  final TokenStore _tokens;
  final Logger _log;
  StreamSubscription<Envelope>? _sub;
  SenderPeer? _rtc;
  Timer? _heartbeat;
  int _hbSeq = 0;

  Future<void> requestJoin({
    required RoomAnnouncePayload room,
    required String deviceName,
    String? pin,
  }) async {
    final name = deviceName.trim();
    if (name.isEmpty) {
      state = state.copyWith(error: 'Nama device wajib diisi');
      throw StateError('empty device name');
    }

    state = state.copyWith(
      status: SenderStatus.requesting,
      room: room,
      deviceName: name,
      clearError: true,
      clearReject: true,
    );

    try {
      await _client.connect(Uri.parse(room.wsUrl));

      final stored = await _tokens.read(room.roomId);
      final deviceId = stored?.deviceId ?? state.deviceId ?? _newId();
      final resume = stored != null &&
              !stored.token.isExpired &&
              stored.deviceId == deviceId
          ? stored.token.value
          : null;

      final lanIp = await resolveLanIpv4();
      final requestId = _newId();

      final payload = JoinRequestPayload(
        requestId: requestId,
        pin: pin?.trim().isEmpty ?? true ? null : pin!.trim(),
        resumeToken: resume,
        device: DeviceInfo(
          deviceId: deviceId,
          name: name,
          username: Platform.environment['USER'] ?? name,
          os: Platform.operatingSystem,
          osVersion: Platform.operatingSystemVersion,
          ip: lanIp?.address,
          appVersion: '0.1.0',
        ),
      );

      _client.send(
        Envelope.create(
          type: EventType.joinRequest,
          roomId: room.roomId,
          payload: payload.toJson(),
        ),
      );

      state = state.copyWith(
        status: SenderStatus.waitingApproval,
        requestId: requestId,
        deviceId: deviceId,
      );
      _log.i(
        'JOIN_REQUEST → ${room.wsUrl} resume=${resume != null}',
      );
    } catch (e, st) {
      _log.e('Join request failed', error: e, stackTrace: st);
      await _client.disconnect();
      state = state.copyWith(
        status: SenderStatus.disconnected,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> startSharing({MediaStream? microphone}) async {
    final room = state.room;
    final deviceId = state.deviceId;
    final token = state.token;
    if (room == null || deviceId == null || token == null) {
      throw StateError('Not approved');
    }

    state = state.copyWith(status: SenderStatus.connecting);
    final quality = StreamQualityPreset.byId(state.qualityId);

    await _rtc?.dispose();
    _rtc = SenderPeer(
      deviceId: deviceId,
      onIce: (candidate) {
        _client.send(
          Envelope.create(
            type: EventType.signalIce,
            roomId: room.roomId,
            payload: SignalIcePayload(
              deviceId: deviceId,
              candidate: candidate.toMap(),
            ).toJson(),
          ),
        );
      },
    );
    await _rtc!.init();
    await _rtc!.startCapture(
      width: quality.width,
      height: quality.height,
      frameRate: quality.frameRate,
      microphone: microphone,
    );

    final offer = await _rtc!.createOffer();
    _client.send(
      Envelope.create(
        type: EventType.signalOffer,
        roomId: room.roomId,
        payload: SignalSdpPayload(
          deviceId: deviceId,
          sdp: offer.sdp ?? '',
          type: offer.type ?? 'offer',
        ).toJson(),
      ),
    );

    _sendDeviceState(DeviceStreamState.streaming);
    state = state.copyWith(
      status: SenderStatus.streaming,
      streamState: DeviceStreamState.streaming,
    );
    _startHeartbeat();
    _log.i('Screen share offer sent (mic=${microphone != null})');
  }

  void setMicMuted(bool muted) {
    _rtc?.setMicMuted(muted);
  }

  Future<void> pauseSharing() async {
    await _rtc?.setPaused(true);
    _sendDeviceState(DeviceStreamState.paused);
    state = state.copyWith(
      status: SenderStatus.idle,
      streamState: DeviceStreamState.paused,
    );
  }

  Future<void> resumeSharing() async {
    await _rtc?.setPaused(false);
    _sendDeviceState(DeviceStreamState.streaming);
    state = state.copyWith(
      status: SenderStatus.streaming,
      streamState: DeviceStreamState.streaming,
    );
  }

  Future<void> stopSharing() async {
    await _rtc?.stopCapture();
    _sendDeviceState(DeviceStreamState.idle);
    state = state.copyWith(
      status: SenderStatus.connected,
      streamState: DeviceStreamState.idle,
    );
  }

  void setQuality(String qualityId) {
    state = state.copyWith(qualityId: qualityId);
  }

  Future<void> leaveRoom() async {
    final room = state.room;
    final deviceId = state.deviceId;
    if (room != null && deviceId != null && _client.isConnected) {
      try {
        _client.send(
          Envelope.create(
            type: EventType.deviceLeft,
            roomId: room.roomId,
            payload: DeviceLeftPayload(
              deviceId: deviceId,
              reason: 'user_leave',
            ).toJson(),
          ),
        );
      } catch (_) {}
    }
    await cancel(clearStoredToken: false);
  }

  Future<void> cancel({bool clearStoredToken = true}) async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _rtc?.dispose();
    _rtc = null;
    final roomId = state.room?.roomId;
    if (clearStoredToken && roomId != null) {
      await _tokens.clear(roomId);
    }
    await _client.disconnect();
    state = JoinSessionState(
      deviceId: state.deviceId ?? _newId(),
      deviceName: state.deviceName,
      qualityId: state.qualityId,
    );
  }

  void _onEnvelope(Envelope envelope) {
    switch (envelope.type) {
      case EventType.joinApproved:
        final payload = JoinApprovedPayload.fromJson(envelope.payload);
        if (payload.requestId != state.requestId &&
            payload.deviceId != state.deviceId) {
          return;
        }
        state = state.copyWith(
          status: SenderStatus.approved,
          token: payload.token,
          deviceId: payload.deviceId,
          clearReject: true,
          clearError: true,
        );
        final room = state.room;
        if (room != null) {
          unawaited(
            _tokens.save(
              StoredRoomToken(
                roomId: room.roomId,
                deviceId: payload.deviceId,
                token: payload.token,
                deviceName: state.deviceName,
                wsUrl: room.wsUrl,
              ),
            ),
          );
        }
        _startHeartbeat();
        state = state.copyWith(status: SenderStatus.connected);
        _log.i(
          'JOIN_APPROVED token=${redactToken(payload.token.value)}',
        );
      case EventType.joinRejected:
        final payload = JoinRejectedPayload.fromJson(envelope.payload);
        state = state.copyWith(
          status: SenderStatus.rejected,
          rejectReason: payload.reason,
        );
        unawaited(_client.disconnect());
        _log.i('JOIN_REJECTED: ${payload.reason}');
      case EventType.accessRevoked:
        final reason =
            AccessRevokedPayload.fromJson(envelope.payload).reason;
        final roomId = state.room?.roomId;
        if (roomId != null) unawaited(_tokens.clear(roomId));
        unawaited(_teardownMedia());
        state = state.copyWith(
          status: SenderStatus.disconnected,
          rejectReason: reason,
          clearToken: true,
          streamState: DeviceStreamState.idle,
        );
        unawaited(_client.disconnect());
        _log.i('ACCESS_REVOKED: $reason');
      case EventType.roomClosed:
        unawaited(_teardownMedia());
        state = state.copyWith(
          status: SenderStatus.disconnected,
          rejectReason: 'Room closed',
          clearToken: true,
          streamState: DeviceStreamState.idle,
        );
        unawaited(_client.disconnect());
      case EventType.signalAnswer:
        final payload = SignalSdpPayload.fromJson(envelope.payload);
        if (payload.deviceId != state.deviceId) return;
        unawaited(
          _rtc?.acceptAnswer(
            RTCSessionDescription(payload.sdp, payload.type),
          ),
        );
      case EventType.signalIce:
        final payload = SignalIcePayload.fromJson(envelope.payload);
        if (payload.deviceId != state.deviceId) return;
        final map = payload.candidate;
        unawaited(
          _rtc?.addIce(
            RTCIceCandidate(
              map['candidate'] as String?,
              map['sdpMid'] as String?,
              map['sdpMLineIndex'] as int?,
            ),
          ),
        );
      case EventType.heartbeat:
        break;
      default:
        break;
    }
  }

  void _sendDeviceState(DeviceStreamState streamState) {
    final room = state.room;
    final deviceId = state.deviceId;
    if (room == null || deviceId == null || !_client.isConnected) return;
    _client.send(
      Envelope.create(
        type: EventType.deviceState,
        roomId: room.roomId,
        payload: DeviceStatePayload(
          deviceId: deviceId,
          state: streamState,
        ).toJson(),
      ),
    );
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(LancastConstants.heartbeatInterval, (_) {
      final room = state.room;
      final deviceId = state.deviceId;
      if (room == null || deviceId == null || !_client.isConnected) return;
      _hbSeq++;
      try {
        _client.send(
          Envelope.create(
            type: EventType.heartbeat,
            roomId: room.roomId,
            payload: HeartbeatPayload(deviceId: deviceId, seq: _hbSeq).toJson(),
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> _teardownMedia() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _rtc?.dispose();
    _rtc = null;
  }

  static String _newId() {
    final r = Random.secure();
    final a = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final b = List.generate(4, (_) => r.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$a$b';
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    unawaited(_sub?.cancel());
    unawaited(_rtc?.dispose() ?? Future.value());
    unawaited(_client.dispose());
    super.dispose();
  }
}
