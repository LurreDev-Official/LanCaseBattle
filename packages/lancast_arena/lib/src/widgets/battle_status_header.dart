import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/domain/battle_models.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';
import 'package:lancast_arena/src/widgets/status_chip.dart';

class BattleStatusHeader extends StatelessWidget {
  const BattleStatusHeader({
    super.key,
    required this.state,
    this.trailing,
  });

  final BattleState state;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final phaseColor = switch (state.phase) {
      BattlePhase.waiting => ArenaColors.muted,
      BattlePhase.countdown => ArenaColors.amber,
      BattlePhase.running => ArenaColors.lime,
      BattlePhase.warning => ArenaColors.crimson,
      BattlePhase.finished => ArenaColors.cyan,
      BattlePhase.paused => ArenaColors.amber,
    };

    return SafeArea(
      bottom: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ArenaColors.deepNavy.withValues(alpha: 0.94),
          border: Border(
            bottom: BorderSide(color: phaseColor.withValues(alpha: 0.45)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 980;
            return Row(
              children: [
                Text(
                  narrow ? 'LCA' : 'LANCAST',
                  style: GoogleFonts.orbitron(
                    color: ArenaColors.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: narrow ? 14 : 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ARENA',
                  style: GoogleFonts.orbitron(
                    color: ArenaColors.ice,
                    fontWeight: FontWeight.w600,
                    fontSize: narrow ? 14 : 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 18, color: ArenaColors.gridLine),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    state.config.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rajdhani(
                      color: ArenaColors.ice,
                      fontWeight: FontWeight.w700,
                      fontSize: narrow ? 15 : 18,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!narrow) ...[
                  StatusChip(
                    label: state.config.category.shortLabel,
                    color: ArenaColors.lime,
                  ),
                  const SizedBox(width: 6),
                ],
                StatusChip(label: state.phaseLabel, color: phaseColor),
                if (!narrow && state.config.roomCode != null) ...[
                  const SizedBox(width: 6),
                  StatusChip(
                    label: 'ROOM ${state.config.roomCode}',
                    color: ArenaColors.cyan,
                  ),
                ],
                const SizedBox(width: 4),
                if (trailing != null) trailing!,
              ],
            );
          },
        ),
      ),
    );
  }
}
