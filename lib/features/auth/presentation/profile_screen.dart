import 'package:flutter/material.dart';

import '../../../shared/widgets/bale_card.dart';
import '../../../theme/bale_theme.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.controller, super.key});

  final AuthController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late int _grade;
  late CareerPath _careerPath;

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
    final user = widget.controller.user;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _ProfileHeader(user: user, onSignOut: widget.controller.signOut),
            const SizedBox(height: 14),
            BaleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Akun',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(user?.role ?? 'STUDENT')),
                      Chip(label: Text('Kelas ${user?.gradeLevel ?? _grade}')),
                      Chip(
                          label: Text((user?.careerPath ?? _careerPath).label)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: BaleColors.success),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Login tersimpan aman di perangkat ini.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BaleCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit Profil',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nama wajib diisi.'
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
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
                            avatar: Icon(_careerIcon(path), size: 18),
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
                      onPressed: widget.controller.isBusy ? null : _save,
                      icon: widget.controller.isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Simpan'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.completeOnboarding(
      fullName: _name.text,
      gradeLevel: _grade,
      careerPath: _careerPath,
    );
    if (mounted && widget.controller.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil tersimpan.')),
      );
    }
  }

  IconData _careerIcon(CareerPath path) => switch (path) {
        CareerPath.detective => Icons.travel_explore_rounded,
        CareerPath.animalDoctor => Icons.health_and_safety_rounded,
        CareerPath.koreanTeacher => Icons.record_voice_over_rounded,
      };
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onSignOut});

  final AuthUser? user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: BaleColors.success,
          child: Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Siswa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(user?.email ?? 'Login kode peserta'),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Keluar',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}
