import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/audio/audio_settings_provider.dart';
import 'package:lancast_viewer/features/devices/domain/connected_device.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';
import 'package:lancast_viewer/features/streaming/presentation/stream_grid.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';

class RoomDashboardScreen extends ConsumerWidget {
  const RoomDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(roomHostProvider);
    final room = host.room;
    final audio = ref.watch(audioSettingsProvider);
    final speakerMuted = audio.state.speakerMuted;

    ref.listen<RoomHostState>(roomHostProvider, (prev, next) {
      final event = next.lastEvent;
      if (event != null && event != prev?.lastEvent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event), duration: const Duration(seconds: 2)),
        );
      }
    });

    ref.listen(audioSettingsProvider, (prev, next) {
      final muted = next.state.speakerMuted;
      ref.read(roomHostProvider.notifier).setAllRemoteAudioEnabled(!muted);
      final outId = next.state.selectedOutputId;
      if (outId != null) {
        Helper.selectAudioOutput(outId).ignore();
      }
    });

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Dashboard')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(ViewerRoutes.createRoom),
            child: const Text('Buat Room'),
          ),
        ),
      );
    }

    final pending = host.pendingRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        actions: [
          IconButton(
            tooltip: speakerMuted ? 'Unmute speakers' : 'Mute speakers',
            onPressed: () {
              final muted = !speakerMuted;
              audio.setSpeakerMuted(muted);
              ref
                  .read(roomHostProvider.notifier)
                  .setAllRemoteAudioEnabled(!muted);
            },
            icon: Icon(speakerMuted ? Icons.volume_off : Icons.volume_up),
          ),
          IconButton(
            tooltip: 'Audio settings',
            onPressed: () => context.go(ViewerRoutes.settings),
            icon: const Icon(Icons.headphones),
          ),
          PopupMenuButton<GridLayoutMode>(
            tooltip: 'Layout',
            initialValue: host.layout,
            onSelected: (v) =>
                ref.read(roomHostProvider.notifier).setLayout(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: GridLayoutMode.one, child: Text('1×1')),
              PopupMenuItem(value: GridLayoutMode.twoByTwo, child: Text('2×2')),
              PopupMenuItem(value: GridLayoutMode.auto, child: Text('Auto')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.grid_view_rounded),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Quality',
            initialValue: host.qualityId,
            onSelected: (v) =>
                ref.read(roomHostProvider.notifier).setQuality(v),
            itemBuilder: (_) => StreamQualityPreset.all
                .map(
                  (q) => PopupMenuItem(value: q.id, child: Text(q.label)),
                )
                .toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.high_quality_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Approval queue',
            onPressed: () => context.go(ViewerRoutes.approval),
            icon: Badge(
              isLabelVisible: pending.isNotEmpty,
              label: Text('${pending.length}'),
              child: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Devices',
            onPressed: () => context.go(ViewerRoutes.devices),
            icon: const Icon(Icons.devices_other_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${room.roomId} · ${room.wsUrl} · peers ${host.peerCount} · ${host.qualityId}'
              '${speakerMuted ? ' · SPEAKER MUTED' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...pending.map(
                (req) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text(req.deviceName),
                    subtitle: Text(
                      [req.os, if (req.ip != null) req.ip!].join(' · '),
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        FilledButton(
                          onPressed: () => ref
                              .read(roomHostProvider.notifier)
                              .approve(req.requestId),
                          child: const Text('Approve'),
                        ),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(roomHostProvider.notifier)
                              .reject(req.requestId),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Expanded(child: StreamGrid()),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => context.go(ViewerRoutes.home),
                  child: const Text('Home'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(roomHostProvider.notifier).stopRoom();
                    if (context.mounted) context.go(ViewerRoutes.home);
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Tutup Room'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
