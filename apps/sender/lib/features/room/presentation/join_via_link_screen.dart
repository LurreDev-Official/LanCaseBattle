import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/discovery/data/room_scan_controller.dart';

class JoinViaLinkScreen extends ConsumerStatefulWidget {
  const JoinViaLinkScreen({super.key, this.initialLink});

  final String? initialLink;

  @override
  ConsumerState<JoinViaLinkScreen> createState() => _JoinViaLinkScreenState();
}

class _JoinViaLinkScreenState extends ConsumerState<JoinViaLinkScreen> {
  late final TextEditingController _linkCtrl;
  String? _error;
  RoomAnnouncePayload? _preview;

  @override
  void initState() {
    super.initState();
    _linkCtrl = TextEditingController(text: widget.initialLink ?? '');
    if (widget.initialLink != null && widget.initialLink!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _parse());
    }
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    final room = RoomJoinLink.tryDecode(_linkCtrl.text);
    setState(() {
      _preview = room;
      _error = room == null ? 'Invalid LanCast join link' : null;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() => _linkCtrl.text = text);
    _parse();
  }

  void _continue() {
    final room = _preview ?? RoomJoinLink.tryDecode(_linkCtrl.text);
    if (room == null) {
      setState(() => _error = 'Invalid LanCast join link');
      return;
    }
    ref.read(roomScanProvider.notifier).selectRoom(room);
    context.go(SenderRoutes.requestJoin);
  }

  @override
  Widget build(BuildContext context) {
    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('JOIN VIA LINK'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(SenderRoutes.home),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: NeonPanel(
              accent: ArenaColors.cyan,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PASTE ARENA INVITE',
                    style: GoogleFonts.shareTechMono(
                      color: ArenaColors.cyan,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan link dari Judge / Viewer (lancast://join?…)',
                    style: GoogleFonts.rajdhani(
                      color: ArenaColors.muted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _linkCtrl,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => _parse(),
                    decoration: const InputDecoration(
                      labelText: 'Join link',
                      hintText: 'lancast://join?room_id=…',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: ArenaColors.crimson),
                    ),
                  ],
                  if (_preview != null) ...[
                    const SizedBox(height: 14),
                    NeonPanel(
                      accent: ArenaColors.lime,
                      glow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _preview!.name.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              color: ArenaColors.ice,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ROOM ${_preview!.roomId}',
                            style: GoogleFonts.shareTechMono(
                              color: ArenaColors.lime,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _preview!.wsUrl,
                            style: GoogleFonts.shareTechMono(
                              color: ArenaColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Owner ${_preview!.ownerName} · '
                            '${_preview!.pinRequired ? 'PIN required' : 'No PIN'}',
                            style: GoogleFonts.rajdhani(
                              color: ArenaColors.muted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _paste,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('PASTE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _preview == null ? null : _continue,
                          icon: const Icon(Icons.login),
                          label: const Text('CONTINUE'),
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
    );
  }
}
