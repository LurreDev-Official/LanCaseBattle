import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showShareJoinLinkDialog(
  BuildContext context, {
  required RoomAnnouncePayload room,
}) {
  final link = RoomJoinLink.encodeString(room);
  final message = RoomJoinLink.shareMessage(room);

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: ArenaColors.panel,
        title: Text(
          'SHARE JOIN LINK',
          style: GoogleFonts.orbitron(
            color: ArenaColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                room.name,
                style: GoogleFonts.rajdhani(
                  color: ArenaColors.ice,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${room.roomId} · ${room.wsUrl}',
                style: GoogleFonts.shareTechMono(
                  color: ArenaColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              NeonPanel(
                glow: false,
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  link,
                  style: GoogleFonts.shareTechMono(
                    color: ArenaColors.lime,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Peserta buka LanCast Sender → Join via Link, lalu paste URL ini. Harus satu LAN.',
                style: GoogleFonts.rajdhani(
                  color: ArenaColors.muted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Join link copied')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('COPY LINK'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Share.share(message, subject: 'LanCast Arena invite');
            },
            icon: const Icon(Icons.ios_share, size: 16),
            label: const Text('SHARE'),
          ),
        ],
      );
    },
  );
}

class ShareJoinLinkButton extends StatelessWidget {
  const ShareJoinLinkButton({
    super.key,
    required this.room,
    this.compact = false,
  });

  final RoomAnnouncePayload room;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Share join link',
        onPressed: () => showShareJoinLinkDialog(context, room: room),
        icon: const Icon(Icons.link),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => showShareJoinLinkDialog(context, room: room),
      icon: const Icon(Icons.link),
      label: const Text('SHARE JOIN LINK'),
    );
  }
}
