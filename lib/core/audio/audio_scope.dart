import 'package:flutter/material.dart';

import 'audio_controller.dart';

class AudioScope extends StatefulWidget {
  const AudioScope({required this.child, super.key});

  final Widget child;

  static AudioController of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_AudioInherited>();
    assert(inherited != null, 'AudioScope was not found in the widget tree.');
    return inherited!.controller;
  }

  static AudioController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AudioInherited>()
        ?.controller;
  }

  @override
  State<AudioScope> createState() => _AudioScopeState();
}

class _AudioScopeState extends State<AudioScope> with WidgetsBindingObserver {
  late final AudioController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioController();
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.setAppInForeground(true);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.setAppInForeground(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AudioInherited(controller: _controller, child: widget.child);
  }
}

class _AudioInherited extends InheritedWidget {
  const _AudioInherited({
    required this.controller,
    required super.child,
  });

  final AudioController controller;

  @override
  bool updateShouldNotify(_AudioInherited oldWidget) {
    return oldWidget.controller != controller;
  }
}
