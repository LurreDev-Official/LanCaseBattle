import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/arena/data/battle_controller.dart';
import 'package:lancast_viewer/features/arena/presentation/share_join_link.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class JudgeDashboardScreen extends ConsumerWidget {
  const JudgeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battle = ref.watch(battleControllerProvider);
    final host = ref.watch(roomHostProvider);
    final ctrl = ref.read(battleControllerProvider.notifier);

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
                  TextButton(
                    onPressed: () => context.go(ViewerRoutes.arena),
                    child: const Text('ARENA HUD'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 1000;
                    final control = NeonPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'JUDGE CONTROL',
                            style: GoogleFonts.shareTechMono(
                              color: ArenaColors.cyan,
                              letterSpacing: 2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: BattleTimerHud(
                              phase: battle.phase,
                              remaining: battle.remaining,
                              countdownRemaining: battle.countdownRemaining,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () => ctrl.startCountdown(),
                                icon: const Icon(Icons.timer_outlined),
                                label: const Text('COUNTDOWN'),
                              ),
                              FilledButton.icon(
                                onPressed: () => ctrl.startBattle(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ArenaColors.lime,
                                ),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('START'),
                              ),
                              OutlinedButton.icon(
                                onPressed: battle.phase == BattlePhase.paused
                                    ? ctrl.resumeBattle
                                    : ctrl.pauseBattle,
                                icon: Icon(
                                  battle.phase == BattlePhase.paused
                                      ? Icons.play_circle_outline
                                      : Icons.pause_circle_outline,
                                ),
                                label: Text(
                                  battle.phase == BattlePhase.paused
                                      ? 'RESUME'
                                      : 'PAUSE',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: ctrl.endBattle,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ArenaColors.crimson,
                                  side: const BorderSide(
                                    color: ArenaColors.crimson,
                                  ),
                                ),
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('END BATTLE'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ctrl.resetToLobby();
                                  context.go(ViewerRoutes.lobby);
                                },
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('RESET LOBBY'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Peers ${host.peerCount} · Pending ${host.pendingRequests.length} · Devices ${host.devices.length}',
                            style: GoogleFonts.rajdhani(
                              color: ArenaColors.muted,
                              fontSize: 15,
                            ),
                          ),
                          if (!stacked) const Spacer(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    context.go(ViewerRoutes.lobby),
                                child: const Text('LOBBY'),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    context.go(ViewerRoutes.approval),
                                child: const Text('APPROVALS'),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    context.go(ViewerRoutes.devices),
                                child: const Text('DEVICES'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final scoring = NeonPanel(
                      accent: ArenaColors.lime,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'TEAM MONITOR + SCORING',
                            style: GoogleFonts.shareTechMono(
                              color: ArenaColors.lime,
                              letterSpacing: 2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: battle.teams.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final team = battle.teams[i];
                                final accent = ArenaColors.teamAccent(i);
                                return NeonPanel(
                                  accent: accent,
                                  glow: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            accent.withValues(alpha: 0.15),
                                        foregroundColor: accent,
                                        child: Text(
                                          team.logoLabel ?? '${i + 1}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              team.teamName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.orbitron(
                                                color: ArenaColors.ice,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${team.playerName ?? 'Open slot'} · ${team.presence.name.toUpperCase()}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.rajdhani(
                                                color: ArenaColors.muted,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => ctrl.setScore(
                                          i,
                                          (team.score - 1)
                                              .clamp(0, 9999)
                                              .toInt(),
                                        ),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text(
                                        '${team.score}',
                                        style: GoogleFonts.orbitron(
                                          color: accent,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            ctrl.setScore(i, team.score + 1),
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );

                    if (stacked) {
                      return Column(
                        children: [
                          control,
                          const SizedBox(height: 12),
                          Expanded(child: scoring),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: control),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: scoring),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
