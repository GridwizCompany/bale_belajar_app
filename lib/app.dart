import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/audio_scope.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'theme/bale_theme.dart';

class BaleBelajarApp extends StatelessWidget {
  const BaleBelajarApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AudioScope(
      child: MaterialApp(
        title: 'Bale Belajar',
        debugShowCheckedModeBanner: false,
        theme: buildBaleTheme(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFFFFF3C6),
              systemNavigationBarColor: Color(0xFFFFF3C6),
              systemNavigationBarDividerColor: Color(0xFFFFF3C6),
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: ColoredBox(
              color: const Color(0xFFFFF3C6),
              child: MediaQuery(
                data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: home ?? const AuthGate(),
      ),
    );
  }
}
