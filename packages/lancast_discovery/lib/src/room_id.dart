import 'dart:math';

/// Builds a readable room id from a display name.
String generateRoomId(String name) {
  final slug = name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final base = slug.isEmpty ? 'ROOM' : slug;
  final suffix = (Random().nextInt(900) + 100).toString();
  final clipped = base.length > 24 ? base.substring(0, 24) : base;
  return '$clipped-$suffix';
}
