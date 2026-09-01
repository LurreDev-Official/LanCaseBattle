import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/discovery/data/room_scan_controller.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roomScanProvider.notifier).startScan());
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(roomScanProvider);

    return ArenaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('FIND BATTLE ROOM'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await ref.read(roomScanProvider.notifier).stopScan();
              if (context.mounted) context.go(SenderRoutes.home);
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh scan',
              onPressed: () => ref.read(roomScanProvider.notifier).startScan(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (scan.isScanning)
              const LinearProgressIndicator(
                minHeight: 2,
                color: ArenaColors.cyan,
                backgroundColor: ArenaColors.gridLine,
              ),
            if (scan.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  scan.error!,
                  style: const TextStyle(color: ArenaColors.crimson),
                ),
              ),
            Expanded(
              child: scan.rooms.isEmpty
                  ? Center(
                      child: Text(
                        scan.isScanning
                            ? 'SCANNING LAN FOR ARENA HOSTS…'
                            : 'NO ROOMS FOUND · START JUDGE / VIEWER FIRST',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: ArenaColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: scan.rooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final room = scan.rooms[index];
                        return NeonPanel(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              room.name.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: ArenaColors.ice,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'OWNER ${room.ownerName} · ${room.securityMode.wire}\n${room.wsUrl}',
                              style: GoogleFonts.rajdhani(
                                color: ArenaColors.muted,
                                fontSize: 15,
                              ),
                            ),
                            isThreeLine: true,
                            trailing: const StatusChip(
                              label: 'JOIN',
                              color: ArenaColors.cyan,
                            ),
                            onTap: () {
                              ref
                                  .read(roomScanProvider.notifier)
                                  .selectRoom(room);
                              context.go(SenderRoutes.requestJoin);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
