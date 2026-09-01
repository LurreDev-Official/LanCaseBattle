import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';
import 'package:lancast_arena/src/widgets/neon_panel.dart';

class JoinApprovalRequest {
  const JoinApprovalRequest({
    required this.requestId,
    required this.deviceName,
    required this.teamHint,
    this.os,
    this.ip,
    this.categoryHint,
  });

  final String requestId;
  final String deviceName;
  final String teamHint;
  final String? os;
  final String? ip;
  final String? categoryHint;
}

Future<bool?> showJoinApprovalDialog(
  BuildContext context, {
  required JoinApprovalRequest request,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Join approval',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Material(
                color: Colors.transparent,
                child: NeonPanel(
                  accent: ArenaColors.amber,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'JOIN REQUEST',
                        style: GoogleFonts.shareTechMono(
                          color: ArenaColors.amber,
                          letterSpacing: 2.4,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New participant requesting arena access',
                        style: GoogleFonts.rajdhani(
                          color: ArenaColors.ice,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _MetaRow(label: 'DEVICE', value: request.deviceName),
                      _MetaRow(label: 'TEAM SLOT', value: request.teamHint),
                      if (request.os != null)
                        _MetaRow(label: 'OS', value: request.os!),
                      if (request.ip != null)
                        _MetaRow(label: 'IP', value: request.ip!),
                      if (request.categoryHint != null)
                        _MetaRow(
                          label: 'CATEGORY',
                          value: request.categoryHint!,
                        ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ArenaColors.crimson,
                                side: const BorderSide(
                                  color: ArenaColors.crimson,
                                ),
                              ),
                              child: const Text('REJECT'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: ArenaColors.lime,
                                foregroundColor: ArenaColors.voidBlack,
                              ),
                              child: const Text('APPROVE'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: ArenaColors.muted,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                color: ArenaColors.ice,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
