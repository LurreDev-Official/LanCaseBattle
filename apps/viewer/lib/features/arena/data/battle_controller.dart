import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_arena/lancast_arena.dart';

final battleControllerProvider =
    StateNotifierProvider<BattleController, BattleState?>((ref) {
  return BattleController();
});

class BattleController extends StateNotifier<BattleState?> {
  BattleController() : super(null);

  Timer? _ticker;

  void configure(BattleConfig config, {List<ArenaTeamSlot>? teams}) {
    _ticker?.cancel();
    state = BattleState(
      config: config,
      phase: BattlePhase.waiting,
      teams: teams ?? ArenaTeamSlot.emptyFour(),
      remaining: config.duration,
      countdownRemaining: config.countdown,
    );
  }

  void updateTeam(int slot, ArenaTeamSlot team) {
    final current = state;
    if (current == null) return;
    final teams = [...current.teams];
    if (slot < 0 || slot >= teams.length) return;
    teams[slot] = team;
    state = current.copyWith(teams: teams);
  }

  void setScore(int slot, int score) {
    final current = state;
    if (current == null) return;
    final teams = [...current.teams];
    if (slot < 0 || slot >= teams.length) return;
    teams[slot] = teams[slot].copyWith(score: score);
    state = current.copyWith(teams: teams);
  }

  void bindDevice({
    required int slot,
    required String deviceId,
    required String playerName,
    String? languageOrTool,
    bool live = false,
  }) {
    final current = state;
    if (current == null) return;
    final teams = [...current.teams];
    if (slot < 0 || slot >= teams.length) return;
    teams[slot] = teams[slot].copyWith(
      playerName: playerName,
      deviceId: deviceId,
      languageOrTool: languageOrTool,
      presence: live ? TeamPresence.live : TeamPresence.online,
      networkMs: 18 + slot * 7,
    );
    state = current.copyWith(teams: teams);
  }

  void startCountdown() {
    final current = state;
    if (current == null) return;
    _ticker?.cancel();
    state = current.copyWith(
      phase: BattlePhase.countdown,
      countdownRemaining: current.config.countdown,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void startBattle() {
    final current = state;
    if (current == null) return;
    _ticker?.cancel();
    state = current.copyWith(
      phase: BattlePhase.running,
      remaining: current.config.duration,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void pauseBattle() {
    final current = state;
    if (current == null) return;
    if (current.phase != BattlePhase.running &&
        current.phase != BattlePhase.warning) {
      return;
    }
    _ticker?.cancel();
    state = current.copyWith(phase: BattlePhase.paused);
  }

  void resumeBattle() {
    final current = state;
    if (current == null || current.phase != BattlePhase.paused) return;
    state = current.copyWith(
      phase: current.remaining.inSeconds <= 60
          ? BattlePhase.warning
          : BattlePhase.running,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void endBattle() {
    _ticker?.cancel();
    final current = state;
    if (current == null) return;
    state = current.copyWith(phase: BattlePhase.finished, remaining: Duration.zero);
  }

  void resetToLobby() {
    final current = state;
    if (current == null) return;
    _ticker?.cancel();
    state = current.copyWith(
      phase: BattlePhase.waiting,
      remaining: current.config.duration,
      countdownRemaining: current.config.countdown,
    );
  }

  void _onTick() {
    final current = state;
    if (current == null) return;

    if (current.phase == BattlePhase.countdown) {
      final next = current.countdownRemaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        state = current.copyWith(
          phase: BattlePhase.running,
          countdownRemaining: Duration.zero,
          remaining: current.config.duration,
        );
      } else {
        state = current.copyWith(countdownRemaining: next);
      }
      return;
    }

    if (current.phase == BattlePhase.running ||
        current.phase == BattlePhase.warning) {
      final next = current.remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        _ticker?.cancel();
        state = current.copyWith(
          phase: BattlePhase.finished,
          remaining: Duration.zero,
        );
      } else if (next.inSeconds <= 60) {
        state = current.copyWith(phase: BattlePhase.warning, remaining: next);
      } else {
        state = current.copyWith(remaining: next);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
