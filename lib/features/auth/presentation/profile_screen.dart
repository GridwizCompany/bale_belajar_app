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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: BaleColors.success,
              child: Icon(Icons.person_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'Siswa',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user?.email ?? 'Login kode peserta'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Keluar',
              onPressed:
                  widget.controller.isBusy ? null : widget.controller.signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BaleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akun Aman', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                  'Token login disimpan di secure storage perangkat dan dikirim sebagai Bearer token ke backend.'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Role: ${user?.role ?? '-'}')),
                  Chip(label: Text('Kelas ${user?.gradeLevel ?? _grade}')),
                  Chip(label: Text((user?.careerPath ?? _careerPath).label)),
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
                Text('Profil Siswa',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty
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
                        onSelected: (_) => setState(() => _careerPath = path),
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
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan Profil'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.completeOnboarding(
      fullName: _name.text,
      gradeLevel: _grade,
      careerPath: _careerPath,
    );
  }
}
