import 'package:flutter/material.dart';

import 'features/baleverse/presentation/baleverse_demo_screen.dart';
import 'theme/bale_theme.dart';

class BaleBelajarApp extends StatelessWidget {
  const BaleBelajarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaleBelajar',
      debugShowCheckedModeBanner: false,
      theme: buildBaleTheme(),
      home: const BaleVerseDemoScreen(),
    );
  }
}
