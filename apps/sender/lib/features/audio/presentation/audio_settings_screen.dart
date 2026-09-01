import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/audio/audio_settings_provider.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';

class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(SenderRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Seperti Zoom: pilih mikrofon & speaker, test, dan mute.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AudioSettingsPanel(
            controller: audio,
            showShareMicrophoneToggle: true,
          ),
        ],
      ),
    );
  }
}
