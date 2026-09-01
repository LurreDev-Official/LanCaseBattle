import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/room/data/join_session_controller.dart';

class WaitingApprovalScreen extends ConsumerWidget {
  const WaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<JoinSessionState>(joinSessionProvider, (prev, next) {
      if (next.status == SenderStatus.approved ||
          next.status == SenderStatus.connected) {
        context.go(SenderRoutes.sharing);
      } else if (next.status == SenderStatus.rejected ||
          next.status == SenderStatus.disconnected) {
        context.go(SenderRoutes.rejected);
      }
    });

    final session = ref.watch(joinSessionProvider);

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: NeonPanel(
            accent: ArenaColors.cyan,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LiveBadge(active: true, label: 'STANDBY'),
                  const SizedBox(height: 18),
                  Text(
                    'WAITING FOR JUDGE',
                    style: GoogleFonts.orbitron(
                      color: ArenaColors.ice,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your join request is in the approval queue.\nDo not close this window.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: ArenaColors.muted,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 18),
                  StatusChip(
                    label: 'STATUS ${session.status.name.toUpperCase()}',
                    color: ArenaColors.cyan,
                  ),
                  if (session.room != null) ...[
                    const SizedBox(height: 8),
                    StatusChip(
                      label: 'ROOM ${session.room!.name}'.toUpperCase(),
                      color: ArenaColors.lime,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ArenaColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(joinSessionProvider.notifier).cancel();
                      if (context.mounted) context.go(SenderRoutes.home);
                    },
                    child: const Text('CANCEL REQUEST'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
