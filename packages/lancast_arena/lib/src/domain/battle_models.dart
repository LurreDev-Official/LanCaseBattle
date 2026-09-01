import 'package:flutter/foundation.dart';

enum BattlePhase {
  waiting,
  countdown,
  running,
  warning,
  finished,
  paused,
}

enum BattleCategory {
  programming,
  cyberBugHunter,
}

extension BattleCategoryX on BattleCategory {
  String get label => switch (this) {
        BattleCategory.programming => 'PROGRAMMING',
        BattleCategory.cyberBugHunter => 'CYBER BUG HUNTER',
      };

  String get shortLabel => switch (this) {
        BattleCategory.programming => 'CODE BATTLE',
        BattleCategory.cyberBugHunter => 'BUG HUNT',
      };
}

enum TeamPresence { empty, offline, online, live }

@immutable
class ArenaTeamSlot {
  const ArenaTeamSlot({
    required this.slotIndex,
    required this.teamName,
    this.playerName,
    this.logoLabel,
    this.score = 0,
    this.languageOrTool,
    this.networkMs,
    this.presence = TeamPresence.empty,
    this.deviceId,
  });

  final int slotIndex;
  final String teamName;
  final String? playerName;
  final String? logoLabel;
  final int score;
  final String? languageOrTool;
  final int? networkMs;
  final TeamPresence presence;
  final String? deviceId;

  bool get isOccupied => presence != TeamPresence.empty;

  ArenaTeamSlot copyWith({
    String? teamName,
    String? playerName,
    String? logoLabel,
    int? score,
    String? languageOrTool,
    int? networkMs,
    TeamPresence? presence,
    String? deviceId,
    bool clearDevice = false,
  }) {
    return ArenaTeamSlot(
      slotIndex: slotIndex,
      teamName: teamName ?? this.teamName,
      playerName: playerName ?? this.playerName,
      logoLabel: logoLabel ?? this.logoLabel,
      score: score ?? this.score,
      languageOrTool: languageOrTool ?? this.languageOrTool,
      networkMs: networkMs ?? this.networkMs,
      presence: presence ?? this.presence,
      deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
    );
  }

  static List<ArenaTeamSlot> emptyFour() => List.generate(
        4,
        (i) => ArenaTeamSlot(
          slotIndex: i,
          teamName: 'TEAM ${String.fromCharCode(65 + i)}',
          logoLabel: String.fromCharCode(65 + i),
        ),
      );
}

@immutable
class BattleConfig {
  const BattleConfig({
    required this.name,
    required this.category,
    required this.duration,
    required this.countdown,
    this.roomCode,
  });

  final String name;
  final BattleCategory category;
  final Duration duration;
  final Duration countdown;
  final String? roomCode;
}

@immutable
class BattleState {
  const BattleState({
    required this.config,
    required this.phase,
    required this.teams,
    required this.remaining,
    this.countdownRemaining = Duration.zero,
  });

  final BattleConfig config;
  final BattlePhase phase;
  final List<ArenaTeamSlot> teams;
  final Duration remaining;
  final Duration countdownRemaining;

  String get phaseLabel => switch (phase) {
        BattlePhase.waiting => 'WAITING',
        BattlePhase.countdown => 'COUNTDOWN',
        BattlePhase.running => 'BATTLE RUNNING',
        BattlePhase.warning => 'WARNING',
        BattlePhase.finished => 'FINISHED',
        BattlePhase.paused => 'PAUSED',
      };

  BattleState copyWith({
    BattleConfig? config,
    BattlePhase? phase,
    List<ArenaTeamSlot>? teams,
    Duration? remaining,
    Duration? countdownRemaining,
  }) {
    return BattleState(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      teams: teams ?? this.teams,
      remaining: remaining ?? this.remaining,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
    );
  }
}
