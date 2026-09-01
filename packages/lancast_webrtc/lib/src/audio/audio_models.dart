class AudioDeviceOption {
  const AudioDeviceOption({
    required this.deviceId,
    required this.label,
    required this.kind,
  });

  final String deviceId;
  final String label;

  /// `audioinput` | `audiooutput`
  final String kind;

  bool get isInput => kind == 'audioinput';
  bool get isOutput => kind == 'audiooutput';
}

class AudioSettingsSnapshot {
  const AudioSettingsSnapshot({
    this.inputs = const [],
    this.outputs = const [],
    this.selectedInputId,
    this.selectedOutputId,
    this.micMuted = false,
    this.speakerMuted = false,
    this.inputVolume = 1.0,
    this.outputVolume = 1.0,
    this.autoGain = true,
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.shareMicrophone = true,
    this.micLevel = 0.0,
    this.isTestingMic = false,
    this.isTestingSpeaker = false,
    this.error,
  });

  final List<AudioDeviceOption> inputs;
  final List<AudioDeviceOption> outputs;
  final String? selectedInputId;
  final String? selectedOutputId;
  final bool micMuted;
  final bool speakerMuted;
  final double inputVolume;
  final double outputVolume;
  final bool autoGain;
  final bool echoCancellation;
  final bool noiseSuppression;
  final bool shareMicrophone;
  final double micLevel;
  final bool isTestingMic;
  final bool isTestingSpeaker;
  final String? error;

  AudioSettingsSnapshot copyWith({
    List<AudioDeviceOption>? inputs,
    List<AudioDeviceOption>? outputs,
    String? selectedInputId,
    String? selectedOutputId,
    bool? micMuted,
    bool? speakerMuted,
    double? inputVolume,
    double? outputVolume,
    bool? autoGain,
    bool? echoCancellation,
    bool? noiseSuppression,
    bool? shareMicrophone,
    double? micLevel,
    bool? isTestingMic,
    bool? isTestingSpeaker,
    String? error,
    bool clearError = false,
    bool clearInput = false,
    bool clearOutput = false,
  }) {
    return AudioSettingsSnapshot(
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      selectedInputId:
          clearInput ? null : (selectedInputId ?? this.selectedInputId),
      selectedOutputId:
          clearOutput ? null : (selectedOutputId ?? this.selectedOutputId),
      micMuted: micMuted ?? this.micMuted,
      speakerMuted: speakerMuted ?? this.speakerMuted,
      inputVolume: inputVolume ?? this.inputVolume,
      outputVolume: outputVolume ?? this.outputVolume,
      autoGain: autoGain ?? this.autoGain,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      shareMicrophone: shareMicrophone ?? this.shareMicrophone,
      micLevel: micLevel ?? this.micLevel,
      isTestingMic: isTestingMic ?? this.isTestingMic,
      isTestingSpeaker: isTestingSpeaker ?? this.isTestingSpeaker,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
