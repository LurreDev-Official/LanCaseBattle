import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class DeviceManagerScreen extends ConsumerWidget {
  const DeviceManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(roomHostProvider).devices;

    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Devices (${devices.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(ViewerRoutes.dashboard),
        ),
      ),
      body: devices.isEmpty
          ? const Center(child: Text('Belum ada device approved'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = devices[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  title: Text(d.name),
                  subtitle: Text(
                    '${d.os} · ${d.streamState.name}'
                    '${d.ip != null ? ' · ${d.ip}' : ''}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove Access'),
                          content: Text('Cabut akses ${d.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(roomHostProvider.notifier)
                            .revokeDevice(d.deviceId);
                      }
                    },
                    child: const Text('Remove'),
                  ),
                );
              },
            ),
    );
  }
}
