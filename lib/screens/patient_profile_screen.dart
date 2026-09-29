import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/features/profile/patient_birth_date.dart';
import 'package:iris/features/emergency_contact/emergency_contact_editor.dart';
import 'package:iris/features/emergency_contact/emergency_contact_repository.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/app_function_header.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.onSignOut,
    this.embeddedInNavigationShell = false,
    this.profileRepository,
    this.emergencyContactDataSource,
  });

  final Future<void> Function() onSignOut;
  final bool embeddedInNavigationShell;
  final ProfileRepository? profileRepository;
  final EmergencyContactDataSource? emergencyContactDataSource;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late final _profileRepository =
      widget.profileRepository ?? ProfileRepository();
  late Future<Profile?> _profileFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getCurrentUserProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = _profileRepository.getCurrentUserProfile();
    });
  }

  Future<void> _editPersonalDetails(Profile profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _PatientPersonalDetailsDialog(
        profile: profile,
        repository: _profileRepository,
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.onSignOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppFunctionHeader(
            title: 'Perfil',
            description: 'Dados da conta e preferências.',
          ),
        ),
        SliverToBoxAdapter(
          child: AppResponsive(
            maxWidth: 680,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            child: FutureBuilder<Profile?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AppSurface(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Não foi possível carregar o perfil',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                final name = snapshot.data?.displayName.trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSurface(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.person_rounded, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name == null || name.isEmpty
                                      ? 'Paciente'
                                      : name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Conta de paciente',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.data case final Profile profile?) ...[
                      AppSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dados pessoais',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              profile.birthDate == null
                                  ? 'Data de nascimento: não informada'
                                  : 'Data de nascimento: ${patientBirthDateDisplay(profile.birthDate!)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.phone.isEmpty
                                  ? 'Telefone: não informado (opcional)'
                                  : 'Telefone: ${profile.phone}',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _editPersonalDetails(profile),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(
                                profile.birthDate == null
                                    ? 'Completar dados'
                                    : 'Editar dados',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    EmergencyContactEditor(
                      dataSource: widget.emergencyContactDataSource,
                    ),
                    const SizedBox(height: 16),
                    AppSurface(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: AppThemeController.mode,
                          builder: (context, mode, _) => SwitchListTile(
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Modo escuro'),
                            value: mode == ThemeMode.dark,
                            onChanged: AppThemeController.setDarkMode,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppSurface(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.shield_outlined),
                              title: const Text('Privacidade e cuidado'),
                              subtitle: const Text(
                                'O compartilhamento dos registros depende dos vínculos e permissões do app.',
                              ),
                            ),
                          ),
                          const Divider(),
                          OutlinedButton.icon(
                            onPressed: _isSigningOut ? null : _signOut,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            icon: _isSigningOut
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout_rounded),
                            label: Text(
                              _isSigningOut ? 'Saindo...' : 'Sair da conta',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInNavigationShell) return content;
    return Scaffold(body: content);
  }
}

class _PatientPersonalDetailsDialog extends StatefulWidget {
  const _PatientPersonalDetailsDialog({
    required this.profile,
    required this.repository,
  });

  final Profile profile;
  final ProfileRepository repository;

  @override
  State<_PatientPersonalDetailsDialog> createState() =>
      _PatientPersonalDetailsDialogState();
}

class _PatientPersonalDetailsDialogState
    extends State<_PatientPersonalDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _birthDate = TextEditingController(
    text: widget.profile.birthDate == null
        ? ''
        : patientBirthDateDisplay(widget.profile.birthDate!),
  );
  late final _phone = TextEditingController(text: widget.profile.phone);
  var _saving = false;

  @override
  void dispose() {
    _birthDate.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.updateCurrentPatientDetails(
        birthDate: parsePatientBirthDate(_birthDate.text)!,
        phone: _phone.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dados pessoais'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('patient-profile-birth-date'),
                controller: _birthDate,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Data de nascimento',
                  hintText: 'DD/MM/AAAA',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe sua data de nascimento.';
                  }
                  return parsePatientBirthDate(value!) == null
                      ? 'Informe uma data válida em DD/MM/AAAA.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  hintText: '(11) 99999-9999',
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) return null;
                  return digits.length < 10 || digits.length > 13
                      ? 'Informe um telefone com DDD.'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
