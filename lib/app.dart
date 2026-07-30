import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'theme/bale_theme.dart';

class BaleBelajarApp extends StatelessWidget {
  const BaleBelajarApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bale Belajar',
      debugShowCheckedModeBanner: false,
      theme: buildBaleTheme(),
      home: home ?? const AuthGate(),
    );
  }
}
