import 'package:flutter/material.dart';

import '../../core/audio/audio_scope.dart';
import '../../core/audio/audio_types.dart';

class AudioUnlockButton extends StatelessWidget {
  const AudioUnlockButton({
    required this.onPressed,
    required this.child,
    this.style,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
              AudioScope.maybeOf(context)?.playSound(SoundEffectId.buttonTap);
              onPressed!();
            },
      child: child,
    );
  }
}
