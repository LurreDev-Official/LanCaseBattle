import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/arena/data/battle_controller.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

/// Set with `--dart-define=AUTO_ROOM=true` for automated join testing.
const bool kAutoRoom = bool.fromEnvironment('AUTO_ROOM');

class ArenaHomeScreen extends ConsumerStatefulWidget {
  const ArenaHomeScreen({super.key});

  @override
  ConsumerState<ArenaHomeScreen> createState() => _ArenaHomeScreenState();
}

class _ArenaHomeScreenState extends ConsumerState<ArenaHomeScreen> {
  var _autoStarted = false;

  @override
  void initState() {
    super.initState();
    if (kAutoRoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoCreate());
    }
  }

  Future<void> _maybeAutoCreate() async {
    if (_autoStarted || !mounted) return;
    _autoStarted = true;
    final host = ref.read(roomHostProvider);
    if (host.isRunning) {
      context.go(ViewerRoutes.arena);
      return;
    }
    try {
      await ref.read(roomHostProvider.notifier).createRoom(
            name: 'AUTO ARENA',
            securityMode: SecurityMode.approvalRequired,
          );
      ref.read(battleControllerProvider.notifier).configure(
            const BattleConfig(
              name: 'AUTO ARENA',
              category: BattleCategory.programming,
              duration: Duration(minutes: 45),
              countdown: Duration(seconds: 10),
              roomCode: 'AUTO',
            ),
          );
      if (!mounted) return;
      context.go(ViewerRoutes.lobby);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AUTO_ROOM failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(roomHostProvider);
    final battle = ref.watch(battleControllerProvider);

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LANCAST ARENA',
                  style: GoogleFonts.orbitron(
                    color: ArenaColors.cyan,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CYBER ESPORTS BATTLE COMMAND CENTER',
                  style: GoogleFonts.shareTechMono(
                    color: ArenaColors.lime,
                    fontSize: 14,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Open-source LAN screen sharing for programming battles\n'
                  'and cyber bug hunter competitions.',
                  style: GoogleFonts.rajdhani(
                    color: ArenaColors.muted,
                    fontSize: 22,
                    height: 1.3,
                  ),
                ),
                if (host.room != null) ...[
                  const SizedBox(height: 20),
                  StatusChip(
                    label:
                        'ACTIVE · ${host.room!.name} · ${host.room!.roomId}',
                    color: ArenaColors.cyan,
                  ),
                ],
                const Spacer(),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(
                        host.isRunning
                            ? (battle == null
                                ? ViewerRoutes.createBattle
                                : ViewerRoutes.lobby)
                            : ViewerRoutes.createBattle,
                      ),
                      icon: const Icon(Icons.sports_esports_outlined),
                      label: Text(
                        host.isRunning ? 'ENTER COMMAND' : 'CREATE BATTLE ROOM',
                      ),
                    ),
                    if (battle != null)
                      OutlinedButton.icon(
                        onPressed: () => context.go(ViewerRoutes.arena),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('OPEN ARENA HUD'),
                      ),
                    if (battle != null)
                      OutlinedButton.icon(
                        onPressed: () => context.go(ViewerRoutes.judge),
                        icon: const Icon(Icons.gavel_outlined),
                        label: const Text('JUDGE DASHBOARD'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(battleControllerProvider.notifier).configure(
                              const BattleConfig(
                                name: 'DEMO OPEN CUP',
                                category: BattleCategory.cyberBugHunter,
                                duration: Duration(minutes: 45),
                                countdown: Duration(seconds: 10),
                                roomCode: 'DEMO',
                              ),
                              teams: [
                                const ArenaTeamSlot(
                                  slotIndex: 0,
                                  teamName: 'NIGHT OWL',
                                  playerName: 'Rina',
                                  logoLabel: 'A',
                                  score: 120,
                                  languageOrTool: 'BURP · PYTHON',
                                  networkMs: 21,
                                  presence: TeamPresence.live,
                                ),
                                const ArenaTeamSlot(
                                  slotIndex: 1,
                                  teamName: 'ZERO TRACE',
                                  playerName: 'Andi',
                                  logoLabel: 'B',
                                  score: 95,
                                  languageOrTool: 'GHIDRA',
                                  networkMs: 34,
                                  presence: TeamPresence.online,
                                ),
                                const ArenaTeamSlot(
                                  slotIndex: 2,
                                  teamName: 'PACKET RAID',
                                  playerName: 'Sari',
                                  logoLabel: 'C',
                                  score: 80,
                                  languageOrTool: 'RUST · WIRES',
                                  networkMs: 18,
                                  presence: TeamPresence.live,
                                ),
                                const ArenaTeamSlot(
                                  slotIndex: 3,
                                  teamName: 'ROOT FLAG',
                                  playerName: 'Bima',
                                  logoLabel: 'D',
                                  score: 70,
                                  languageOrTool: 'KALI · GO',
                                  networkMs: 42,
                                  presence: TeamPresence.online,
                                ),
                              ],
                            );
                        ref
                            .read(battleControllerProvider.notifier)
                            .startCountdown();
                        context.go(ViewerRoutes.arena);
                      },
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('PREVIEW ARENA HUD'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(ViewerRoutes.settings),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('SETTINGS'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'TARGET DISPLAY 1920×1080 · PROTOCOL v${LancastConstants.protocolVersion}',
                  style: GoogleFonts.shareTechMono(
                    color: ArenaColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
