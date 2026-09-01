import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/audio/audio_settings_provider.dart';
import 'package:lancast_sender/features/room/data/join_session_controller.dart';
import 'package:lancast_webrtc/lancast_webrtc.dart';

class SharingConsoleScreen extends ConsumerWidget {
  const SharingConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(joinSessionProvider);
    final audio = ref.watch(audioSettingsProvider);
    final audioState = audio.state;

    ref.listen<JoinSessionState>(joinSessionProvider, (prev, next) {
      if (next.status == SenderStatus.disconnected ||
          next.status == SenderStatus.rejected) {
        context.go(SenderRoutes.rejected);
      }
    });

    final canShare = session.token != null &&
        (session.status == SenderStatus.approved ||
            session.status == SenderStatus.connected ||
            session.status == SenderStatus.idle ||
            session.status == SenderStatus.streaming);

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('SHARING CONSOLE'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Audio settings',
              onPressed: () => context.go(SenderRoutes.audioSettings),
              icon: Icon(
                audioState.micMuted ? Icons.mic_off : Icons.mic_none,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            NeonPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (session.room?.name ?? 'NO ROOM').toUpperCase(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      LiveBadge(
                        active: session.streamState ==
                            DeviceStreamState.streaming,
                        label: session.streamState == DeviceStreamState.streaming
                            ? 'LIVE'
                            : 'IDLE',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Device: ${session.deviceName}'),
                  Text('Status: ${session.status.name}'),
                  Text('Stream: ${session.streamState.name}'),
                  Text('Token: ${redactToken(session.token?.value)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Quality',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: session.qualityId,
                  items: StreamQualityPreset.all
                      .map(
                        (q) => DropdownMenuItem(
                          value: q.id,
                          child: Text(q.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(joinSessionProvider.notifier).setQuality(v);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            NeonPanel(
              accent: ArenaColors.lime,
              child: AudioSettingsPanel(
                controller: audio,
                showShareMicrophoneToggle: true,
                compact: true,
              ),
            ),
            const SizedBox(height: 24),
            if (session.streamState != DeviceStreamState.streaming)
              FilledButton.icon(
                onPressed: !canShare
                    ? null
                    : () async {
                        try {
                          final mic = await audio.openMicStream();
                          if (mic != null && audioState.micMuted) {
                            for (final t in mic.getAudioTracks()) {
                              t.enabled = false;
                            }
                          }
                          await ref
                              .read(joinSessionProvider.notifier)
                              .startSharing(microphone: mic);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share failed: $e')),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  audioState.shareMicrophone
                      ? 'START SHARE (SCREEN + MIC)'
                      : 'START SHARE (SCREEN ONLY)',
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final muted = !audioState.micMuted;
                        audio.setMicMuted(muted);
                        ref
                            .read(joinSessionProvider.notifier)
                            .setMicMuted(muted);
                      },
                      icon: Icon(
                        audioState.micMuted ? Icons.mic_off : Icons.mic,
                      ),
                      label: Text(audioState.micMuted ? 'UNMUTE' : 'MUTE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(joinSessionProvider.notifier)
                          .pauseSharing(),
                      icon: const Icon(Icons.pause),
                      label: const Text('PAUSE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(joinSessionProvider.notifier).stopSharing(),
                icon: const Icon(Icons.stop),
                label: const Text('STOP SHARE'),
              ),
            ],
            if (session.streamState == DeviceStreamState.paused) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(joinSessionProvider.notifier).resumeSharing(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('RESUME'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await ref.read(joinSessionProvider.notifier).leaveRoom();
                if (context.mounted) context.go(SenderRoutes.home);
              },
              icon: const Icon(Icons.logout),
              label: const Text('LEAVE ARENA'),
            ),
          ],
        ),
      ),
    );
  }
}
