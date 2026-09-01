import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/core/constants/app_info.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

/// Set with `--dart-define=AUTO_ROOM=true` for automated join testing.
const bool kAutoRoom = bool.fromEnvironment('AUTO_ROOM');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _autoStarted = false;

  @override
  void initState() {
    super.initState();
    if (kAutoRoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoCreate());
    }
  }

  Future<void> _maybeAutoCreate() async {
    if (_autoStarted || !mounted) return;
    _autoStarted = true;
    final host = ref.read(roomHostProvider);
    if (host.isRunning) {
      context.go(ViewerRoutes.dashboard);
      return;
    }
    try {
      await ref.read(roomHostProvider.notifier).createRoom(
            name: 'AUTO TEST',
            securityMode: SecurityMode.approvalRequired,
          );
      if (!mounted) return;
      context.go(ViewerRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AUTO_ROOM failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final host = ref.watch(roomHostProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppInfo.name,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppInfo.roleLabel,
                style: textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Buat room lokal, approve device, tampilkan screen share di LAN.',
                style: textTheme.bodyLarge,
              ),
              if (kAutoRoom) ...[
                const SizedBox(height: 8),
                Text(
                  'AUTO_ROOM=true — room dibuat otomatis untuk testing',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              if (host.room != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Room aktif: ${host.room!.name} (${host.room!.roomId})',
                  style: textTheme.bodyMedium,
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go(
                  host.isRunning
                      ? ViewerRoutes.dashboard
                      : ViewerRoutes.createRoom,
                ),
                icon: Icon(
                  host.isRunning
                      ? Icons.grid_view_rounded
                      : Icons.add_box_outlined,
                ),
                label: Text(host.isRunning ? 'Buka Dashboard' : 'Buat Room'),
              ),
              if (!host.isRunning) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(ViewerRoutes.createRoom),
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Room Baru'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(ViewerRoutes.settings),
                child: const Text('Pengaturan'),
              ),
              const SizedBox(height: 16),
              Text(
                'Protocol v${LancastConstants.protocolVersion} · WS :${LancastConstants.signalingPort} · UDP :${LancastConstants.udpBroadcastPort}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
