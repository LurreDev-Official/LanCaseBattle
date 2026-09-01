import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/arena/data/battle_controller.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class CreateBattleScreen extends ConsumerStatefulWidget {
  const CreateBattleScreen({super.key});

  @override
  ConsumerState<CreateBattleScreen> createState() => _CreateBattleScreenState();
}

class _CreateBattleScreenState extends ConsumerState<CreateBattleScreen> {
  final _nameCtrl = TextEditingController(text: 'LANCAST OPEN CUP');
  final _teamCtrls = List.generate(
    4,
    (i) => TextEditingController(text: 'TEAM ${String.fromCharCode(65 + i)}'),
  );

  BattleCategory _category = BattleCategory.programming;
  int _durationMin = 45;
  int _countdownSec = 10;
  var _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _teamCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final host = ref.read(roomHostProvider);
      if (!host.isRunning) {
        await ref.read(roomHostProvider.notifier).createRoom(
              name: _nameCtrl.text.trim().isEmpty
                  ? 'Arena Battle'
                  : _nameCtrl.text.trim(),
              securityMode: SecurityMode.approvalRequired,
            );
      }
      final room = ref.read(roomHostProvider).room;
      final teams = List.generate(4, (i) {
        final name = _teamCtrls[i].text.trim();
        return ArenaTeamSlot(
          slotIndex: i,
          teamName: name.isEmpty ? 'TEAM ${String.fromCharCode(65 + i)}' : name,
          logoLabel: String.fromCharCode(65 + i),
          languageOrTool: _category == BattleCategory.programming
              ? 'READY'
              : 'TOOLS READY',
        );
      });

      ref.read(battleControllerProvider.notifier).configure(
            BattleConfig(
              name: _nameCtrl.text.trim().isEmpty
                  ? 'Arena Battle'
                  : _nameCtrl.text.trim(),
              category: _category,
              duration: Duration(minutes: _durationMin),
              countdown: Duration(seconds: _countdownSec),
              roomCode: room?.roomId,
            ),
            teams: teams,
          );

      if (!mounted) return;
      context.go(ViewerRoutes.lobby);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('CREATE BATTLE ROOM'),
          leading: IconButton(
            onPressed: () => context.go(ViewerRoutes.home),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: NeonPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'BATTLE CONFIGURATION',
                      style: GoogleFonts.shareTechMono(
                        color: ArenaColors.cyan,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Battle name',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CATEGORY',
                      style: GoogleFonts.shareTechMono(
                        color: ArenaColors.muted,
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        _CatChip(
                          label: 'PROGRAMMING',
                          selected:
                              _category == BattleCategory.programming,
                          onTap: () => setState(
                            () => _category = BattleCategory.programming,
                          ),
                        ),
                        _CatChip(
                          label: 'CYBER BUG HUNTER',
                          selected:
                              _category == BattleCategory.cyberBugHunter,
                          onTap: () => setState(
                            () =>
                                _category = BattleCategory.cyberBugHunter,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _SliderBlock(
                            label: 'DURATION',
                            valueLabel: '$_durationMin MIN',
                            value: _durationMin.toDouble(),
                            min: 10,
                            max: 120,
                            divisions: 22,
                            onChanged: (v) =>
                                setState(() => _durationMin = v.round()),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _SliderBlock(
                            label: 'COUNTDOWN',
                            valueLabel: '$_countdownSec SEC',
                            value: _countdownSec.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            onChanged: (v) =>
                                setState(() => _countdownSec = v.round()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'TEAM SLOTS (4)',
                      style: GoogleFonts.shareTechMono(
                        color: ArenaColors.muted,
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 88,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, i) {
                        final accent = ArenaColors.teamAccent(i);
                        return NeonPanel(
                          accent: accent,
                          glow: false,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    accent.withValues(alpha: 0.15),
                                foregroundColor: accent,
                                child: Text(String.fromCharCode(65 + i)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _teamCtrls[i],
                                  decoration: InputDecoration(
                                    labelText: 'Team ${i + 1}',
                                    isDense: true,
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _busy ? null : _create,
                      child: Text(
                        _busy ? 'INITIALIZING…' : 'CREATE & OPEN LOBBY',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.cyan.withValues(alpha: 0.18)
              : ArenaColors.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? ArenaColors.cyan : ArenaColors.gridLine,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: selected ? ArenaColors.cyan : ArenaColors.muted,
            letterSpacing: 1.2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: ArenaColors.muted,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: GoogleFonts.orbitron(
                color: ArenaColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: ArenaColors.cyan,
          inactiveColor: ArenaColors.gridLine,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
