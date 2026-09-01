import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_webrtc/src/rtc_config.dart';

typedef ViewerIceHandler = void Function(RTCIceCandidate candidate);
typedef TrackHandler = void Function(MediaStream stream);

/// Viewer-side peer that answers sender offers.
class ViewerPeer {
  ViewerPeer({
    required this.deviceId,
    this.onIce,
    this.onTrack,
  });

  final String deviceId;
  final ViewerIceHandler? onIce;
  final TrackHandler? onTrack;

  RTCPeerConnection? _pc;
  final renderer = RTCVideoRenderer();
  MediaStream? remoteStream;
  bool _ready = false;
  bool _remoteAudioEnabled = true;

  bool get isReady => _ready;

  Future<void> init() async {
    await renderer.initialize();
    _pc = await createPeerConnection(lancastRtcConfiguration());
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIce?.call(candidate);
      }
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams.first;
        renderer.srcObject = remoteStream;
        // Re-apply speaker mute preference when tracks arrive.
        unawaited(setRemoteAudioEnabled(_remoteAudioEnabled));
        onTrack?.call(remoteStream!);
      }
    };
    _ready = true;
  }

  Future<RTCSessionDescription> acceptOffer(RTCSessionDescription offer) async {
    final pc = _pc;
    if (pc == null) {
      throw StateError('ViewerPeer not initialized');
    }
    await pc.setRemoteDescription(offer);
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    return answer;
  }

  Future<void> addIce(RTCIceCandidate candidate) async {
    await _pc?.addCandidate(candidate);
  }

  Future<void> setRemoteAudioEnabled(bool enabled) async {
    _remoteAudioEnabled = enabled;
    final tracks = remoteStream?.getAudioTracks() ?? [];
    for (final t in tracks) {
      t.enabled = enabled;
    }
  }

  Future<void> dispose() async {
    await remoteStream?.dispose();
    remoteStream = null;
    await _pc?.close();
    _pc = null;
    await renderer.dispose();
    _ready = false;
  }
}
