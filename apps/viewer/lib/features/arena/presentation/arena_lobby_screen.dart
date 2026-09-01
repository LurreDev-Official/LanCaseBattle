import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/arena/data/battle_controller.dart';
import 'package:lancast_viewer/features/arena/presentation/share_join_link.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class ArenaLobbyScreen extends ConsumerStatefulWidget {
  const ArenaLobbyScreen({super.key});

  @override
  ConsumerState<ArenaLobbyScreen> createState() => _ArenaLobbyScreenState();
}

class _ArenaLobbyScreenState extends ConsumerState<ArenaLobbyScreen> {
  String? _shownRequestId;

  @override
  Widget build(BuildContext context) {
    final battle = ref.watch(battleControllerProvider);
    final host = ref.watch(roomHostProvider);

    ref.listen(roomHostProvider, (prev, next) async {
      final pending = next.pendingRequests;
      if (pending.isEmpty) return;
      final req = pending.first;
      if (_shownRequestId == req.requestId) return;
      _shownRequestId = req.requestId;

      final approved = await showJoinApprovalDialog(
        context,
        request: JoinApprovalRequest(
          requestId: req.requestId,
          deviceName: req.deviceName,
          teamHint: _nextOpenSlotLabel(battle),
          os: req.os,
          ip: req.ip,
          categoryHint: battle?.config.category.label,
        ),
      );
      if (!mounted) return;
      if (approved == true) {
        ref.read(roomHostProvider.notifier).approve(req.requestId);
        final slot = _nextOpenSlotIndex(battle);
        if (slot != null) {
          ref.read(battleControllerProvider.notifier).bindDevice(
                slot: slot,
                deviceId: req.requestId,
                playerName: req.deviceName,
                languageOrTool: battle?.config.category ==
                        BattleCategory.cyberBugHunter
                    ? 'HUNTER GEAR'
                    : 'CODE READY',
              );
        }
      } else if (approved == false) {
        ref.read(roomHostProvider.notifier).reject(req.requestId);
      }
      _shownRequestId = null;
    });

    if (battle == null) {
      return ArenaBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: FilledButton(
              onPressed: () => context.go(ViewerRoutes.createBattle),
              child: const Text('CREATE BATTLE FIRST'),
            ),
          ),
        ),
      );
    }

    final readyCount =
        battle.teams.where((t) => t.presence != TeamPresence.empty).length;

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            BattleStatusHeader(
              state: battle,
              trailing: Row(
                children: [
                  TextButton(
                    onPressed: () => context.go(ViewerRoutes.judge),
                    child: const Text('JUDGE'),
                  ),
                  TextButton(
                    onPressed: () => context.go(ViewerRoutes.arena),
                    child: const Text('ARENA'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).height < 800 ? 16 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LOBBY · WAITING ROOM',
                      style: GoogleFonts.orbitron(
                        color: ArenaColors.ice,
                        fontSize:
                            MediaQuery.sizeOf(context).height < 800 ? 20 : 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      host.room == null
                          ? 'Configure teams, approve participants, then start countdown.'
                          : 'Room ${host.room!.roomId} · ${host.room!.wsUrl} · pending ${host.pendingRequests.length}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rajdhani(
                        color: ArenaColors.muted,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ArenaTeamGrid(teams: battle.teams),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 720;
                        final announce = host.room?.toAnnouncePayload();
                        final actions = <Widget>[
                          StatusChip(
                            label: '$readyCount / 4 SLOTS FILLED',
                            color: ArenaColors.lime,
                          ),
                          if (!narrow) const Spacer(),
                          if (announce != null)
                            ShareJoinLinkButton(room: announce),
                          if (!narrow && announce != null)
                            const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () =>
                                context.go(ViewerRoutes.approval),
                            child: const Text('APPROVAL QUEUE'),
                          ),
                          if (!narrow) const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(battleControllerProvider.notifier)
                                  .startCountdown();
                              context.go(ViewerRoutes.arena);
                            },
                            icon: const Icon(Icons.timer_outlined),
                            label: const Text('START COUNTDOWN'),
                          ),
                        ];
                        if (narrow) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: actions,
                          );
                        }
                        return Row(children: actions);
                      },
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

  String _nextOpenSlotLabel(BattleState? battle) {
    final i = _nextOpenSlotIndex(battle);
    if (i == null) return 'FULL';
    return battle!.teams[i].teamName;
  }

  int? _nextOpenSlotIndex(BattleState? battle) {
    if (battle == null) return 0;
    for (var i = 0; i < battle.teams.length; i++) {
      if (battle.teams[i].presence == TeamPresence.empty) return i;
    }
    return null;
  }
}
