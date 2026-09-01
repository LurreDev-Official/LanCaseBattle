import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/core/constants/app_info.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/audio/audio_settings_provider.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(ViewerRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Aplikasi'),
            subtitle: Text(AppInfo.name),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Versi'),
            subtitle: Text(AppInfo.version),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Signaling port'),
            subtitle: Text('${LancastConstants.signalingPort}'),
          ),
          const Divider(height: 32),
          Text(
            'Audio (input / output)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pengaturan mirip Zoom: pilih speaker untuk mendengar stream, '
            'test perangkat, dan mute output.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AudioSettingsPanel(controller: audio),
        ],
      ),
    );
  }
}
