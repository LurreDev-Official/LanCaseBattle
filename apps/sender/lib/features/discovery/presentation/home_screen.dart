import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/core/router/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LANCAST ARENA',
                  style: GoogleFonts.orbitron(
                    color: ArenaColors.cyan,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PARTICIPANT NODE',
                  style: GoogleFonts.shareTechMono(
                    color: ArenaColors.lime,
                    letterSpacing: 2.2,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover a battle room on the LAN, request judge approval,\n'
                  'then share your screen into the arena grid.',
                  style: GoogleFonts.rajdhani(
                    color: ArenaColors.muted,
                    fontSize: 20,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                NeonPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  FilledButton.icon(
                    onPressed: () => context.go(SenderRoutes.roomList),
                    icon: const Icon(Icons.wifi_find_outlined),
                    label: const Text('FIND BATTLE ROOM'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(SenderRoutes.joinLink),
                    icon: const Icon(Icons.link),
                    label: const Text('JOIN VIA LINK'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(SenderRoutes.sharing),
                    icon: const Icon(Icons.cast_outlined),
                    label: const Text('SHARING CONSOLE'),
                  ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(SenderRoutes.audioSettings),
                        icon: const Icon(Icons.headphones),
                        label: const Text('AUDIO SETTINGS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'PROTOCOL v${LancastConstants.protocolVersion} · PARTICIPANT CLIENT',
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
