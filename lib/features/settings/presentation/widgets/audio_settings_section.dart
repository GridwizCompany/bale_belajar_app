import 'package:flutter/material.dart';

import '../../../../core/audio/audio_scope.dart';

class AudioSettingsSection extends StatelessWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AudioScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        return Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pengaturan Suara',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Efek Suara',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Efek Suara'),
                    value: state.soundEnabled,
                    onChanged: controller.setSoundEnabled,
                  ),
                ),
                Semantics(
                  label: 'Musik Latar',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Musik Latar'),
                    value: state.musicEnabled,
                    onChanged: controller.setMusicEnabled,
                  ),
                ),
                _VolumeSlider(
                  label: 'Volume Efek',
                  value: state.soundVolume,
                  onChanged: controller.setSoundVolume,
                ),
                _VolumeSlider(
                  label: 'Volume Musik',
                  value: state.musicVolume,
                  onChanged: controller.setMusicVolume,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Putar Contoh',
                        button: true,
                        child: FilledButton(
                          onPressed: state.soundEnabled
                              ? controller.previewSound
                              : null,
                          child: const Text('Putar Contoh'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        label: 'Atur Ulang',
                        button: true,
                        child: OutlinedButton(
                          onPressed: controller.resetSettings,
                          child: const Text('Atur Ulang'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    return Semantics(
      label: '$label $percentage persen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('$percentage%'),
            ],
          ),
          Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
