import 'package:flutter/material.dart';

import '../../../../shared/widgets/bale_card.dart';
import '../../../../theme/bale_theme.dart';
import '../widgets/baleverse_widgets.dart';

class LoginDemoScreen extends StatelessWidget {
  const LoginDemoScreen({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageShell(
          children: [
            BaleCard(
              color: BaleColors.soft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SmallCaps('Demo siswa'),
                  const SizedBox(height: 12),
                  Text(
                    'Masuk ke BaleVerse',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: BaleColors.ink),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Coba alur belajar berbasis misi dengan dummy data. Tidak ada backend atau AI API yang dipakai.',
                    style: TextStyle(
                      color: BaleColors.earth,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Masuk sebagai Nara'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
