import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_webrtc/src/rtc_config.dart';

typedef SenderIceHandler = void Function(RTCIceCandidate candidate);

/// Sender-side peer that publishes display media (+ optional microphone).
class SenderPeer {
  SenderPeer({
    required this.deviceId,
    this.onIce,
  });

  final String deviceId;
  final SenderIceHandler? onIce;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _micStream;
  bool _ready = false;

  bool get isReady => _ready;
  MediaStream? get localStream => _localStream;
  MediaStream? get micStream => _micStream;

  Future<void> init() async {
    _pc = await createPeerConnection(lancastRtcConfiguration());
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIce?.call(candidate);
      }
    };
    _ready = true;
  }

  Future<void> startCapture({
    int width = 1280,
    int height = 720,
    int frameRate = 30,
    MediaStream? microphone,
  }) async {
    final pc = _pc;
    if (pc == null) throw StateError('SenderPeer not initialized');

    await stopCapture();
    _localStream = await navigator.mediaDevices.getDisplayMedia(
      displayMediaConstraints(
        width: width,
        height: height,
        frameRate: frameRate,
      ),
    );
    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    if (microphone != null) {
      _micStream = microphone;
      for (final track in microphone.getAudioTracks()) {
        await pc.addTrack(track, microphone);
      }
    }
  }

  Future<void> setPaused(bool paused) async {
    final tracks = _localStream?.getVideoTracks() ?? [];
    for (final t in tracks) {
      t.enabled = !paused;
    }
  }

  void setMicMuted(bool muted) {
    final tracks = _micStream?.getAudioTracks() ?? [];
    for (final t in tracks) {
      t.enabled = !muted;
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final pc = _pc;
    if (pc == null) throw StateError('SenderPeer not initialized');
    final offer = await pc.createOffer({
      'offerToReceiveAudio': false,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(offer);
    return offer;
  }

  Future<void> acceptAnswer(RTCSessionDescription answer) async {
    await _pc?.setRemoteDescription(answer);
  }

  Future<void> addIce(RTCIceCandidate candidate) async {
    await _pc?.addCandidate(candidate);
  }

  Future<void> stopCapture() async {
    final tracks = [
      ..._localStream?.getTracks() ?? [],
      ..._micStream?.getTracks() ?? [],
    ];
    for (final t in tracks) {
      await t.stop();
    }
    await _localStream?.dispose();
    await _micStream?.dispose();
    _localStream = null;
    _micStream = null;
  }

  Future<void> dispose() async {
    await stopCapture();
    await _pc?.close();
    _pc = null;
    _ready = false;
  }
}
