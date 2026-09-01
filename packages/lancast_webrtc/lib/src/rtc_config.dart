/// LAN-first RTC configuration (no cloud TURN required).
Map<String, dynamic> lancastRtcConfiguration({
  int width = 1280,
  int height = 720,
  int frameRate = 30,
}) {
  return {
    'iceServers': <Map<String, dynamic>>[],
    'sdpSemantics': 'unified-plan',
  };
}

Map<String, dynamic> displayMediaConstraints({
  int width = 1280,
  int height = 720,
  int frameRate = 30,
}) {
  return {
    'video': {
      'width': width,
      'height': height,
      'frameRate': frameRate,
    },
    'audio': false,
  };
}

class StreamQualityPreset {
  const StreamQualityPreset({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.frameRate,
  });

  final String id;
  final String label;
  final int width;
  final int height;
  final int frameRate;

  static const p720 = StreamQualityPreset(
    id: '720p30',
    label: '720p30',
    width: 1280,
    height: 720,
    frameRate: 30,
  );

  static const p1080 = StreamQualityPreset(
    id: '1080p30',
    label: '1080p30',
    width: 1920,
    height: 1080,
    frameRate: 30,
  );

  static const List<StreamQualityPreset> all = [p720, p1080];

  static StreamQualityPreset byId(String id) {
    return all.firstWhere((e) => e.id == id, orElse: () => p720);
  }
}
