import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class VolumeSettingsSheet extends StatelessWidget {
  const VolumeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 12),
                const Text(
                  'Audio',
                  style: TextStyle(
                    fontFamily: 'SpellOfAsia',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _VolumeSlider(
              title: 'Background music',
              notifier: musicVolumeNotifier,
              onChanged: AudioService.instance.setMusicVolume,
            ),
            const SizedBox(height: 24),
            _VolumeSlider(
              title: 'Effects',
              notifier: sfxVolumeNotifier,
              onChanged: AudioService.instance.setSfxVolume,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.title,
    required this.notifier,
    required this.onChanged,
  });

  final String title;
  final ValueNotifier<double> notifier;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: notifier,
          builder: (context, volume, _) {
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: volume.clamp(0.0, 1.0),
                divisions: 20,
                onChanged: onChanged,
              ),
            );
          },
        ),
      ],
    );
  }
}
