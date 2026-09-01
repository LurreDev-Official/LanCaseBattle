import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_viewer/features/devices/domain/connected_device.dart';
import 'package:lancast_viewer/features/room/data/room_host_controller.dart';

class StreamGrid extends ConsumerWidget {
  const StreamGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(roomHostProvider);
    final devices = host.devices;
    final layout = host.layout;

    if (devices.isEmpty) {
      return Center(
        child: Text(
          'Menunggu device approved / stream…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    final crossAxis = switch (layout) {
      GridLayoutMode.one => 1,
      GridLayoutMode.twoByTwo => 2,
      GridLayoutMode.auto => devices.length <= 1
          ? 1
          : devices.length <= 4
              ? 2
              : 3,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 10,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final renderer =
            ref.read(roomHostProvider.notifier).rendererFor(device.deviceId);
        return _DeviceTile(device: device, renderer: renderer);
      },
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.renderer});

  final ConnectedDevice device;
  final RTCVideoRenderer? renderer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: renderer != null && device.hasRemoteVideo
                  ? RTCVideoView(
                      renderer!,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    )
                  : Center(
                      child: Text(
                        device.streamState == DeviceStreamState.idle
                            ? 'Idle'
                            : 'Connecting…',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StateChip(state: device.streamState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final DeviceStreamState state;

  @override
  Widget build(BuildContext context) {
    final label = state.name.toUpperCase();
    final color = switch (state) {
      DeviceStreamState.streaming => Colors.greenAccent,
      DeviceStreamState.paused => Colors.orangeAccent,
      DeviceStreamState.idle => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}
