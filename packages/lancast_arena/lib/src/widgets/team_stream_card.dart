import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/domain/battle_models.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';
import 'package:lancast_arena/src/widgets/live_badge.dart';

class TeamStreamCard extends StatelessWidget {
  const TeamStreamCard({
    super.key,
    required this.team,
    this.streamChild,
    this.onTap,
    this.compact = false,
  });

  final ArenaTeamSlot team;
  final Widget? streamChild;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = ArenaColors.teamAccent(team.slotIndex);
    final online = team.presence == TeamPresence.online ||
        team.presence == TeamPresence.live;
    final live = team.presence == TeamPresence.live;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = compact || constraints.maxHeight < 220;
        final headerH = tight ? 40.0 : 48.0;
        final footerH = tight ? 30.0 : 36.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: ArenaColors.panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: live
                      ? accent
                      : accent.withValues(alpha: online ? 0.55 : 0.25),
                  width: live ? 2 : 1.2,
                ),
                boxShadow: live
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: headerH,
                    child: _Header(
                      team: team,
                      accent: accent,
                      online: online,
                      live: live,
                      compact: tight,
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: ArenaColors.voidBlack,
                      child: streamChild ??
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  team.presence == TeamPresence.empty
                                      ? 'WAITING FOR TEAM'
                                      : 'NO SIGNAL',
                                  style: GoogleFonts.shareTechMono(
                                    color: ArenaColors.muted,
                                    letterSpacing: 1.5,
                                    fontSize: tight ? 10 : 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    height: footerH,
                    child: _Footer(
                      team: team,
                      accent: accent,
                      compact: tight,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.team,
    required this.accent,
    required this.online,
    required this.live,
    required this.compact,
  });

  final ArenaTeamSlot team;
  final Color accent;
  final bool online;
  final bool live;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatar = compact ? 26.0 : 32.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            ArenaColors.panelElevated,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatar,
            height: avatar,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.5),
              color: ArenaColors.voidBlack,
            ),
            child: Text(
              team.logoLabel ?? team.teamName.characters.first,
              style: GoogleFonts.orbitron(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 13,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    color: ArenaColors.ice,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                if (!compact)
                  Text(
                    team.playerName?.toUpperCase() ?? 'OPEN SLOT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rajdhani(
                      color: ArenaColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          LiveBadge(
            active: live,
            label: live ? 'LIVE' : (online ? 'ON' : 'OFF'),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.team,
    required this.accent,
    required this.compact,
  });

  final ArenaTeamSlot team;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final net = team.networkMs;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      color: ArenaColors.panelElevated,
      child: Row(
        children: [
          Text(
            'SCORE',
            style: GoogleFonts.shareTechMono(
              color: ArenaColors.muted,
              fontSize: compact ? 9 : 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${team.score}',
            style: GoogleFonts.orbitron(
              color: accent,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          if (team.languageOrTool != null)
            Flexible(
              child: Text(
                team.languageOrTool!.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.shareTechMono(
                  color: ArenaColors.ice,
                  fontSize: compact ? 9 : 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          const Spacer(),
          Icon(
            Icons.wifi_tethering,
            size: compact ? 12 : 14,
            color: net == null
                ? ArenaColors.muted
                : net < 40
                    ? ArenaColors.lime
                    : net < 100
                        ? ArenaColors.amber
                        : ArenaColors.crimson,
          ),
          const SizedBox(width: 4),
          Text(
            net == null ? '--' : '${net}ms',
            style: GoogleFonts.shareTechMono(
              color: ArenaColors.muted,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
