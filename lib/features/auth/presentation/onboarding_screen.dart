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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Text(
                  'Atur Belajarmu',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tiga pilihan cepat supaya misi pertama langsung sesuai.',
                ),
                const SizedBox(height: 16),
                const _StepRow(),
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
                            labelText: 'Nama panggilan atau lengkap',
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
                            DropdownMenuItem(
                                value: 10, child: Text('Kelas 10')),
                            DropdownMenuItem(
                                value: 11, child: Text('Kelas 11')),
                            DropdownMenuItem(
                                value: 12, child: Text('Kelas 12')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _grade = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pilih minat belajar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final path in CareerPath.values) ...[
                          _CareerOption(
                            path: path,
                            selected: _careerPath == path,
                            onTap: () => setState(() => _careerPath = path),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (widget.controller.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.controller.errorMessage!,
                            style: const TextStyle(
                              color: BaleColors.danger,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: widget.controller.isBusy ? null : _submit,
                          icon: widget.controller.isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: const Text('Mulai Belajar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _StepRow extends StatelessWidget {
  const _StepRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StepPill(icon: Icons.person_rounded, label: 'Nama')),
        SizedBox(width: 8),
        Expanded(child: _StepPill(icon: Icons.school_rounded, label: 'Kelas')),
        SizedBox(width: 8),
        Expanded(child: _StepPill(icon: Icons.explore_rounded, label: 'Minat')),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: BaleColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BaleColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: BaleColors.success),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerOption extends StatelessWidget {
  const _CareerOption({
    required this.path,
    required this.selected,
    required this.onTap,
  });

  final CareerPath path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? BaleColors.info.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? BaleColors.info : BaleColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(path),
              color: selected ? BaleColors.info : BaleColors.ink,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                path.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? BaleColors.info : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(CareerPath path) => switch (path) {
        CareerPath.detective => Icons.travel_explore_rounded,
        CareerPath.animalDoctor => Icons.health_and_safety_rounded,
        CareerPath.koreanTeacher => Icons.record_voice_over_rounded,
      };
}
