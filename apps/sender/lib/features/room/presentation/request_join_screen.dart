import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/discovery/data/room_scan_controller.dart';
import 'package:lancast_sender/features/room/data/join_session_controller.dart';

class RequestJoinScreen extends ConsumerStatefulWidget {
  const RequestJoinScreen({super.key});

  @override
  ConsumerState<RequestJoinScreen> createState() => _RequestJoinScreenState();
}

class _RequestJoinScreenState extends ConsumerState<RequestJoinScreen> {
  final _nameController = TextEditingController(text: 'Player-01');
  final _pinController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = ref.read(roomScanProvider).selected;
    if (selected == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(joinSessionProvider.notifier).requestJoin(
            room: selected,
            deviceName: _nameController.text,
            pin: _pinController.text,
          );
      if (!mounted) return;
      context.go(SenderRoutes.waiting);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(roomScanProvider).selected;

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('REQUEST JOIN'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _busy ? null : () => context.go(SenderRoutes.roomList),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: NeonPanel(
              accent: ArenaColors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ARENA ACCESS REQUEST',
                    style: GoogleFonts.shareTechMono(
                      color: ArenaColors.amber,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selected?.name.toUpperCase() ?? 'NO ROOM SELECTED',
                    style: GoogleFonts.orbitron(
                      color: ArenaColors.ice,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Player / device name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'PIN (optional)',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: selected == null || _busy ? null : _submit,
                    child: Text(_busy ? 'SENDING…' : 'REQUEST APPROVAL'),
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
