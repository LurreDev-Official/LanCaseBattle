import 'package:flutter/material.dart';
import 'package:lancast_webrtc/src/audio/audio_settings_controller.dart';

/// Zoom-style audio input/output settings panel.
class AudioSettingsPanel extends StatelessWidget {
  const AudioSettingsPanel({
    super.key,
    required this.controller,
    this.showShareMicrophoneToggle = false,
    this.compact = false,
  });

  final AudioSettingsController controller;
  final bool showShareMicrophoneToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final s = controller.state;
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Audio', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh devices',
                  onPressed: controller.refreshDevices,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (s.error != null) ...[
              Text(
                s.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            _DeviceDropdown(
              label: 'Microphone',
              icon: Icons.mic_none,
              value: s.selectedInputId,
              items: s.inputs
                  .map((d) => DropdownMenuItem(
                        value: d.deviceId,
                        child: Text(d.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (id) => controller.selectInput(id),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.micMuted ? 'Mic muted' : 'Input level',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: s.micMuted ? 'Unmute' : 'Mute',
                  onPressed: () => controller.setMicMuted(!s.micMuted),
                  icon: Icon(s.micMuted ? Icons.mic_off : Icons.mic),
                ),
                OutlinedButton(
                  onPressed: s.isTestingMic
                      ? controller.stopMicTest
                      : controller.startMicTest,
                  child: Text(s.isTestingMic ? 'Stop Test' : 'Test Mic'),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.micMuted ? 0 : s.micLevel,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text('Microphone volume', style: theme.textTheme.bodySmall),
            Slider(
              value: s.inputVolume,
              onChanged: controller.setInputVolume,
            ),
            const SizedBox(height: 8),
            _DeviceDropdown(
              label: 'Speaker',
              icon: Icons.volume_up_outlined,
              value: s.selectedOutputId,
              items: s.outputs
                  .map((d) => DropdownMenuItem(
                        value: d.deviceId,
                        child: Text(d.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (id) => controller.selectOutput(id),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.speakerMuted ? 'Speaker muted' : 'Speaker volume',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: s.speakerMuted ? 'Unmute speaker' : 'Mute speaker',
                  onPressed: () =>
                      controller.setSpeakerMuted(!s.speakerMuted),
                  icon: Icon(
                    s.speakerMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                ),
                OutlinedButton(
                  onPressed:
                      s.isTestingSpeaker ? null : controller.testSpeaker,
                  child: Text(
                    s.isTestingSpeaker ? 'Playing…' : 'Test Speaker',
                  ),
                ),
              ],
            ),
            Slider(
              value: s.speakerMuted ? 0 : s.outputVolume,
              onChanged: s.speakerMuted ? null : controller.setOutputVolume,
            ),
            if (!compact) ...[
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Echo cancellation'),
                value: s.echoCancellation,
                onChanged: controller.setEchoCancellation,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Noise suppression'),
                value: s.noiseSuppression,
                onChanged: controller.setNoiseSuppression,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto adjust mic volume'),
                value: s.autoGain,
                onChanged: controller.setAutoGain,
              ),
              if (showShareMicrophoneToggle)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share microphone while screen sharing'),
                  subtitle: const Text(
                    'Mirip Zoom: kirim suara mic bersama layar',
                  ),
                  value: s.shareMicrophone,
                  onChanged: controller.setShareMicrophone,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effective = items.any((e) => e.value == value) ? value : null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: effective,
          hint: Text(items.isEmpty ? 'No devices' : 'Select…'),
          items: items,
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}
