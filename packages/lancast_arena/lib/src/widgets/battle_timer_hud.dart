import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/domain/battle_models.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';

class BattleTimerHud extends StatelessWidget {
  const BattleTimerHud({
    super.key,
    required this.phase,
    required this.remaining,
    this.countdownRemaining = Duration.zero,
    this.compact = false,
  });

  final BattlePhase phase;
  final Duration remaining;
  final Duration countdownRemaining;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isCountdown = phase == BattlePhase.countdown;
    final isWarning =
        phase == BattlePhase.warning || remaining.inSeconds <= 60;
    final isFinished = phase == BattlePhase.finished;

    final display = isCountdown ? countdownRemaining : remaining;
    final color = switch (phase) {
      BattlePhase.waiting => ArenaColors.muted,
      BattlePhase.countdown => ArenaColors.amber,
      BattlePhase.running => ArenaColors.cyan,
      BattlePhase.warning => ArenaColors.crimson,
      BattlePhase.finished => ArenaColors.lime,
      BattlePhase.paused => ArenaColors.amber,
    };

    final mm = display.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = display.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = isFinished ? '00:00' : '$mm:$ss';

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = compact ||
            constraints.maxHeight < 120 ||
            MediaQuery.sizeOf(context).height < 720;
        final fontSize = short ? 28.0 : 48.0;
        final labelSize = short ? 10.0 : 12.0;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: isWarning && !isFinished ? 1.03 : 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: isWarning ? scale : 1, child: child);
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: short ? 14 : 22,
                vertical: short ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: ArenaColors.voidBlack.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phase.hudLabel,
                    style: GoogleFonts.shareTechMono(
                      color: color,
                      fontSize: labelSize,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: GoogleFonts.orbitron(
                      color: ArenaColors.ice,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on BattlePhase {
  String get hudLabel => switch (this) {
        BattlePhase.waiting => 'WAITING',
        BattlePhase.countdown => 'COUNTDOWN',
        BattlePhase.running => 'BATTLE RUNNING',
        BattlePhase.warning => 'WARNING',
        BattlePhase.finished => 'FINISHED',
        BattlePhase.paused => 'PAUSED',
      };
}
