import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_viewer/core/router/app_router.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(roomHostProvider);
    final pending = host.pendingRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text('Approval Queue (${pending.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(ViewerRoutes.dashboard),
        ),
      ),
      body: pending.isEmpty
          ? const Center(child: Text('Belum ada join request'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = pending[index];
                final time =
                    TimeOfDay.fromDateTime(req.createdAt).format(context);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.deviceName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('OS: ${req.os}'),
                        if (req.ip != null) Text('IP: ${req.ip}'),
                        if (req.username != null) Text('User: ${req.username}'),
                        Text('Time: $time'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () => ref
                                  .read(roomHostProvider.notifier)
                                  .approve(req.requestId),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(roomHostProvider.notifier)
                                  .reject(req.requestId),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
