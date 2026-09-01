import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/arena/data/battle_controller.dart';
import 'package:lancast_viewer/features/arena/presentation/share_join_link.dart';
import 'package:lancast_viewer/features/devices/domain/connected_device.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class BattleArenaScreen extends ConsumerWidget {
  const BattleArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battle = ref.watch(battleControllerProvider);
    final host = ref.watch(roomHostProvider);

    ref.listen(roomHostProvider, (prev, next) {
      final b = ref.read(battleControllerProvider);
      if (b == null) return;
      final ctrl = ref.read(battleControllerProvider.notifier);
      for (var i = 0; i < b.teams.length; i++) {
        final team = b.teams[i];
        if (team.deviceId == null) continue;
        ConnectedDevice? match;
        for (final d in next.devices) {
          if (d.deviceId == team.deviceId || d.name == team.playerName) {
            match = d;
            break;
          }
        }
        if (match == null && i < next.devices.length && !team.isOccupied) {
          match = next.devices[i];
        }
        if (match == null) continue;
        final live = match.streamState == DeviceStreamState.streaming &&
            match.hasRemoteVideo;
        ctrl.bindDevice(
          slot: i,
          deviceId: match.deviceId,
          playerName: match.name,
          languageOrTool: team.languageOrTool,
          live: live,
        );
      }

      var slot = 0;
      for (final d in next.devices) {
        while (slot < b.teams.length && b.teams[slot].deviceId != null) {
          slot++;
        }
        if (slot >= b.teams.length) break;
        final already = b.teams.any((t) => t.deviceId == d.deviceId);
        if (already) continue;
        final live =
            d.streamState == DeviceStreamState.streaming && d.hasRemoteVideo;
        ctrl.bindDevice(
          slot: slot,
          deviceId: d.deviceId,
          playerName: d.name,
          languageOrTool: b.config.category == BattleCategory.programming
              ? 'STREAMING'
              : 'HUNTING',
          live: live,
        );
        slot++;
      }
    });

    if (battle == null) {
      return ArenaBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: FilledButton(
              onPressed: () => context.go(ViewerRoutes.createBattle),
              child: const Text('CREATE BATTLE'),
            ),
          ),
        ),
      );
    }

    Widget? streamFor(int i, ArenaTeamSlot team) {
      final deviceId = team.deviceId;
      if (deviceId != null) {
        final renderer =
            ref.read(roomHostProvider.notifier).rendererFor(deviceId);
        final device =
            host.devices.where((d) => d.deviceId == deviceId).firstOrNull;
        if (renderer != null && device != null && device.hasRemoteVideo) {
          return RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          );
        }
      }
      if (i < host.devices.length) {
        final d = host.devices[i];
        final renderer =
            ref.read(roomHostProvider.notifier).rendererFor(d.deviceId);
        if (renderer != null && d.hasRemoteVideo) {
          return RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          );
        }
      }
      return null;
    }

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            BattleStatusHeader(
              state: battle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (host.room != null)
                    ShareJoinLinkButton(
                      room: host.room!.toAnnouncePayload(),
                      compact: true,
                    ),
                  IconButton(
                    tooltip: 'Lobby',
                    onPressed: () => context.go(ViewerRoutes.lobby),
                    icon: const Icon(Icons.meeting_room_outlined),
                  ),
                  IconButton(
                    tooltip: 'Judge',
                    onPressed: () => context.go(ViewerRoutes.judge),
                    icon: const Icon(Icons.gavel_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ArenaTeamGrid(
                      teams: battle.teams,
                      streamBuilder: streamFor,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: BattleTimerHud(
                          phase: battle.phase,
                          remaining: battle.remaining,
                          countdownRemaining: battle.countdownRemaining,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
