import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_webrtc/src/audio/audio_models.dart';

/// Zoom-like audio input/output session (device pick, mute, levels, tests).
class AudioSettingsController extends ChangeNotifier {
  AudioSettingsSnapshot _state = const AudioSettingsSnapshot();
  MediaStream? _meterStream;
  Timer? _meterTimer;
  Timer? _speakerTestTimer;

  AudioSettingsSnapshot get state => _state;

  Map<String, dynamic> micConstraints({String? deviceId}) {
    final id = deviceId ?? _state.selectedInputId;
    return {
      'audio': {
        if (id != null && id.isNotEmpty) 'deviceId': id,
        'echoCancellation': _state.echoCancellation,
        'noiseSuppression': _state.noiseSuppression,
        'autoGainControl': _state.autoGain,
      },
      'video': false,
    };
  }

  Future<void> refreshDevices() async {
    try {
      // Prompt permission so labels are populated on some platforms.
      try {
        final tmp = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        await Future.wait(tmp.getTracks().map((t) async => t.stop()));
        await tmp.dispose();
      } catch (_) {
        // Permission may already be granted / denied — still try enumerate.
      }

      final devices = await navigator.mediaDevices.enumerateDevices();
      final inputs = <AudioDeviceOption>[];
      final outputs = <AudioDeviceOption>[];
      for (final d in devices) {
        final kind = d.kind ?? '';
        final id = d.deviceId;
        if (id.isEmpty) continue;
        final label = (d.label.trim().isEmpty)
            ? (kind == 'audioinput'
                ? 'Microphone (${id.substring(0, id.length.clamp(0, 6))})'
                : 'Speaker (${id.substring(0, id.length.clamp(0, 6))})')
            : d.label;
        final option = AudioDeviceOption(
          deviceId: id,
          label: label,
          kind: kind,
        );
        if (kind == 'audioinput') inputs.add(option);
        if (kind == 'audiooutput') outputs.add(option);
      }

      var inputId = _state.selectedInputId;
      var outputId = _state.selectedOutputId;
      if (inputId == null || !inputs.any((e) => e.deviceId == inputId)) {
        inputId = inputs.isEmpty ? null : inputs.first.deviceId;
      }
      if (outputId == null || !outputs.any((e) => e.deviceId == outputId)) {
        outputId = outputs.isEmpty ? null : outputs.first.deviceId;
      }

      _state = _state.copyWith(
        inputs: inputs,
        outputs: outputs,
        selectedInputId: inputId,
        selectedOutputId: outputId,
        clearError: true,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  Future<void> selectInput(String? deviceId) async {
    _state = _state.copyWith(selectedInputId: deviceId, clearInput: deviceId == null);
    notifyListeners();
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await Helper.selectAudioInput(deviceId);
      } catch (_) {
        // Desktop may not support Helper.selectAudioInput.
      }
    }
    if (_state.isTestingMic) {
      await stopMicTest();
      await startMicTest();
    }
  }

  Future<void> selectOutput(String? deviceId) async {
    _state = _state.copyWith(
      selectedOutputId: deviceId,
      clearOutput: deviceId == null,
    );
    notifyListeners();
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await Helper.selectAudioOutput(deviceId);
      } catch (_) {}
    }
  }

  void setMicMuted(bool muted) {
    _state = _state.copyWith(micMuted: muted);
    final tracks = _meterStream?.getAudioTracks() ?? [];
    for (final t in tracks) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  void setSpeakerMuted(bool muted) {
    _state = _state.copyWith(speakerMuted: muted);
    notifyListeners();
  }

  void setInputVolume(double value) {
    _state = _state.copyWith(inputVolume: value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setOutputVolume(double value) {
    _state = _state.copyWith(outputVolume: value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setAutoGain(bool value) {
    _state = _state.copyWith(autoGain: value);
    notifyListeners();
  }

  void setEchoCancellation(bool value) {
    _state = _state.copyWith(echoCancellation: value);
    notifyListeners();
  }

  void setNoiseSuppression(bool value) {
    _state = _state.copyWith(noiseSuppression: value);
    notifyListeners();
  }

  void setShareMicrophone(bool value) {
    _state = _state.copyWith(shareMicrophone: value);
    notifyListeners();
  }

  Future<void> startMicTest() async {
    await stopMicTest();
    try {
      _meterStream = await navigator.mediaDevices.getUserMedia(
        micConstraints(),
      );
      for (final t in _meterStream!.getAudioTracks()) {
        t.enabled = !_state.micMuted;
      }
      _state = _state.copyWith(isTestingMic: true, micLevel: 0.15, clearError: true);
      notifyListeners();

      // Approximate level animation (full WebAudio analyser is platform-limited).
      var tick = 0;
      _meterTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        tick++;
        if (_state.micMuted) {
          _state = _state.copyWith(micLevel: 0);
        } else {
          final wave = 0.25 + 0.55 * ((tick % 10) / 10);
          _state = _state.copyWith(
            micLevel: (wave * _state.inputVolume).clamp(0.0, 1.0),
          );
        }
        notifyListeners();
      });
    } catch (e) {
      _state = _state.copyWith(
        isTestingMic: false,
        error: 'Gagal akses mikrofon: $e',
      );
      notifyListeners();
    }
  }

  Future<void> stopMicTest() async {
    _meterTimer?.cancel();
    _meterTimer = null;
    final tracks = _meterStream?.getTracks() ?? [];
    for (final t in tracks) {
      await t.stop();
    }
    await _meterStream?.dispose();
    _meterStream = null;
    _state = _state.copyWith(isTestingMic: false, micLevel: 0);
    notifyListeners();
  }

  Future<void> testSpeaker() async {
    _speakerTestTimer?.cancel();
    _state = _state.copyWith(isTestingSpeaker: true, clearError: true);
    notifyListeners();

    if (_state.selectedOutputId != null) {
      try {
        await Helper.selectAudioOutput(_state.selectedOutputId!);
      } catch (_) {}
    }

    // Brief simulated playback indicator (OS plays via WebRTC/helper where available).
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    _speakerTestTimer = Timer(const Duration(seconds: 2), () {
      _state = _state.copyWith(isTestingSpeaker: false);
      notifyListeners();
    });
  }

  Future<MediaStream?> openMicStream() async {
    if (!_state.shareMicrophone || _state.micMuted) return null;
    final stream = await navigator.mediaDevices.getUserMedia(micConstraints());
    for (final t in stream.getAudioTracks()) {
      t.enabled = !_state.micMuted;
    }
    return stream;
  }

  @override
  void dispose() {
    _meterTimer?.cancel();
    _speakerTestTimer?.cancel();
    unawaited(stopMicTest());
    super.dispose();
  }
}
