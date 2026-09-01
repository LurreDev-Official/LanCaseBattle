import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_sender/core/router/app_router.dart';
import 'package:lancast_sender/features/room/data/join_session_controller.dart';

class RejectedScreen extends ConsumerWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = ref.watch(joinSessionProvider).rejectReason ?? 'Admin denied';

    return Scaffold(
      appBar: AppBar(title: const Text('Ditolak')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Join ditolak',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(reason, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await ref.read(joinSessionProvider.notifier).cancel();
                if (context.mounted) context.go(SenderRoutes.home);
              },
              child: const Text('Kembali ke Scan'),
            ),
          ],
        ),
      ),
    );
  }
}
