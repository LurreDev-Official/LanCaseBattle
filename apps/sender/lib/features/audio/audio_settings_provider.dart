import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';

final audioSettingsProvider =
    ChangeNotifierProvider<AudioSettingsController>((ref) {
  final controller = AudioSettingsController();
  ref.onDispose(controller.dispose);
  // Fire-and-forget device refresh.
  Future.microtask(controller.refreshDevices);
  return controller;
});
