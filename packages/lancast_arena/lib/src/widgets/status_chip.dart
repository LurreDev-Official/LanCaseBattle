import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color = ArenaColors.cyan,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
