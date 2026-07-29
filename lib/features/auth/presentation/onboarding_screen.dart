import 'package:flutter/material.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  int _grade = 10;
  CareerPath _careerPath = CareerPath.detective;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.user;
    _name = TextEditingController(text: user?.name ?? '');
    _grade = user?.gradeLevel ?? 10;
    _careerPath = user?.careerPath ?? CareerPath.detective;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text('Lengkapi Profil',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
                'Data ini dipakai untuk menyesuaikan misi dan progres belajar.'),
            const SizedBox(height: 16),
            BaleCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nama wajib diisi.'
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _grade,
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        prefixIcon: Icon(Icons.school_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('Kelas 10')),
                        DropdownMenuItem(value: 11, child: Text('Kelas 11')),
                        DropdownMenuItem(value: 12, child: Text('Kelas 12')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _grade = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final path in CareerPath.values)
                          ChoiceChip(
                            label: Text(path.label),
                            selected: _careerPath == path,
                            onSelected: (_) =>
                                setState(() => _careerPath = path),
                          ),
                      ],
                    ),
                    if (widget.controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.controller.errorMessage!,
                        style: const TextStyle(
                          color: BaleColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: widget.controller.isBusy ? null : _submit,
                      icon: widget.controller.isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: const Text('Mulai Belajar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.completeOnboarding(
      fullName: _name.text,
      gradeLevel: _grade,
      careerPath: _careerPath,
    );
  }
}
