import 'package:flutter/material.dart';
import 'package:lancast_arena/src/domain/battle_models.dart';
import 'package:lancast_arena/src/widgets/team_stream_card.dart';

/// Responsive 2×2 team grid that always fills available space (no clipping).
class ArenaTeamGrid extends StatelessWidget {
  const ArenaTeamGrid({
    super.key,
    required this.teams,
    this.streamBuilder,
    this.gap = 10,
    this.onTeamTap,
  });

  final List<ArenaTeamSlot> teams;
  final Widget? Function(int index, ArenaTeamSlot team)? streamBuilder;
  final double gap;
  final void Function(int index, ArenaTeamSlot team)? onTeamTap;

  @override
  Widget build(BuildContext context) {
    assert(teams.length >= 4, 'ArenaTeamGrid expects 4 team slots');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520 || constraints.maxWidth < 900;
        final g = compact ? 8.0 : gap;

        Widget cell(int i) {
          final team = teams[i];
          return TeamStreamCard(
            team: team,
            compact: compact,
            streamChild: streamBuilder?.call(i, team),
            onTap: onTeamTap == null ? null : () => onTeamTap!(i, team),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(0)),
                  SizedBox(width: g),
                  Expanded(child: cell(1)),
                ],
              ),
            ),
            SizedBox(height: g),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(2)),
                  SizedBox(width: g),
                  Expanded(child: cell(3)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
