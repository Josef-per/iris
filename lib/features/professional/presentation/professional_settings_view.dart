import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalSettingsView extends StatefulWidget {
  const ProfessionalSettingsView({super.key, required this.store});

  final ProfessionalFrontendStore store;

  @override
  State<ProfessionalSettingsView> createState() =>
      _ProfessionalSettingsViewState();
}

class _ProfessionalSettingsViewState extends State<ProfessionalSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _specialty;
  late final TextEditingController _registration;
  late final TextEditingController _biography;
  late final TextEditingController _clinic;
  late final TextEditingController _clinicAddress;

  late bool _appointmentNotifications;
  late bool _crisisAlerts;
  late bool _automaticReports;
  late String _avatarInitials;
  final _devices = <String>['Chrome · Este dispositivo', 'Android · São Paulo'];

  @override
  void initState() {
    super.initState();
    final settings = widget.store.settings;
    _name = TextEditingController(text: settings.name);
    _email = TextEditingController(text: settings.email);
    _phone = TextEditingController(text: settings.phone);
    _specialty = TextEditingController(text: settings.specialty);
    _registration = TextEditingController(text: settings.registration);
    _biography = TextEditingController(text: settings.biography);
    _clinic = TextEditingController(text: settings.clinic);
    _clinicAddress = TextEditingController(text: settings.clinicAddress);
    _appointmentNotifications = settings.appointmentNotifications;
    _crisisAlerts = settings.crisisAlerts;
    _automaticReports = settings.automaticReports;
    _avatarInitials = settings.avatarInitials;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _specialty.dispose();
    _registration.dispose();
    _biography.dispose();
    _clinic.dispose();
    _clinicAddress.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.updateSettings(
      ProfessionalSettingsDraft(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        specialty: _specialty.text.trim(),
        registration: _registration.text.trim(),
        biography: _biography.text.trim(),
        clinic: _clinic.text.trim(),
        clinicAddress: _clinicAddress.text.trim(),
        avatarInitials: _avatarInitials,
        appointmentNotifications: _appointmentNotifications,
        crisisAlerts: _crisisAlerts,
        automaticReports: _automaticReports,
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
  }

  Future<void> _changeAvatar() async {
    final value = await showProfessionalTextItemForm(
      context,
      title: 'Foto do perfil',
      label: 'Iniciais',
      initialValue: _avatarInitials,
    );
    if (value == null) return;
    setState(
      () => _avatarInitials = value
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((part) => part.characters.first)
          .join()
          .toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Perfil e configurações',
            subtitle: 'Dados e preferências',
            action: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.deepPurple,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar'),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  final profile = Column(
                    children: [
                      _ProfilePanel(
                        avatarInitials: _avatarInitials,
                        onAvatarPressed: _changeAvatar,
                        name: _name,
                        email: _email,
                        phone: _phone,
                        specialty: _specialty,
                        registration: _registration,
                        biography: _biography,
                      ),
                      const SizedBox(height: 20),
                      _ClinicPanel(clinic: _clinic, address: _clinicAddress),
                    ],
                  );
                  final preferences = Column(
                    children: [
                      _NotificationsPanel(
                        appointmentNotifications: _appointmentNotifications,
                        crisisAlerts: _crisisAlerts,
                        automaticReports: _automaticReports,
                        onAppointmentChanged: (value) =>
                            setState(() => _appointmentNotifications = value),
                        onCrisisChanged: (value) =>
                            setState(() => _crisisAlerts = value),
                        onReportsChanged: (value) =>
                            setState(() => _automaticReports = value),
                      ),
                      const SizedBox(height: 20),
                      const _AppearancePanel(),
                      const SizedBox(height: 20),
                      _SecurityPanel(
                        onChangePassword: _changePassword,
                        onManageDevices: _showDevices,
                      ),
                    ],
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        profile,
                        const SizedBox(height: 20),
                        preferences,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: profile),
                      const SizedBox(width: 20),
                      Expanded(flex: 9, child: preferences),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar senha'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (value) => value == null || value.length < 8
                      ? 'Use pelo menos 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                  ),
                  validator: (value) =>
                      value != password.text ? 'As senhas não conferem' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    current.dispose();
    password.dispose();
    confirmation.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Senha alterada.')));
    }
  }

  Future<void> _showDevices() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dispositivos'),
          content: SizedBox(
            width: 440,
            child: _devices.isEmpty
                ? const Text('Nenhum dispositivo conectado.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final device in _devices)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.devices_outlined),
                          title: Text(device),
                          trailing: IconButton(
                            tooltip: 'Desconectar',
                            onPressed: () {
                              setState(() => _devices.remove(device));
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _requiredField(String? value) {
  return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.avatarInitials,
    required this.onAvatarPressed,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.registration,
    required this.biography,
  });

  final String avatarInitials;
  final VoidCallback onAvatarPressed;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController specialty;
  final TextEditingController registration;
  final TextEditingController biography;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Dados profissionais'),
          const SizedBox(height: 22),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avatarInitials,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IconButton.filled(
                    tooltip: 'Alterar foto',
                    onPressed: onAvatarPressed,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _ResponsiveFields(
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: _requiredField,
              ),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail profissional',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final error = _requiredField(value);
                  if (error != null) return error;
                  return value!.contains('@') ? null : 'E-mail inválido';
                },
              ),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _requiredField,
              ),
              TextFormField(
                controller: registration,
                decoration: const InputDecoration(
                  labelText: 'Registro profissional',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: _requiredField,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: specialty,
            decoration: const InputDecoration(
              labelText: 'Especialidade',
              prefixIcon: Icon(Icons.psychology_alt_outlined),
            ),
            validator: _requiredField,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: biography,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Biografia',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 74),
                child: Icon(Icons.description_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicPanel extends StatelessWidget {
  const _ClinicPanel({required this.clinic, required this.address});

  final TextEditingController clinic;
  final TextEditingController address;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Dados da clínica'),
          const SizedBox(height: 20),
          TextFormField(
            controller: clinic,
            decoration: const InputDecoration(
              labelText: 'Nome da clínica',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
            validator: _requiredField,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: address,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: _requiredField,
          ),
        ],
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel({
    required this.appointmentNotifications,
    required this.crisisAlerts,
    required this.automaticReports,
    required this.onAppointmentChanged,
    required this.onCrisisChanged,
    required this.onReportsChanged,
  });

  final bool appointmentNotifications;
  final bool crisisAlerts;
  final bool automaticReports;
  final ValueChanged<bool> onAppointmentChanged;
  final ValueChanged<bool> onCrisisChanged;
  final ValueChanged<bool> onReportsChanged;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Notificações'),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: appointmentNotifications,
            onChanged: onAppointmentChanged,
            title: const Text('Lembretes de consultas'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: crisisAlerts,
            onChanged: onCrisisChanged,
            title: const Text('Alertas de crise'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: automaticReports,
            onChanged: onReportsChanged,
            title: const Text('Relatórios automáticos'),
          ),
        ],
      ),
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Aparência'),
          const SizedBox(height: 12),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppThemeController.mode,
            builder: (context, mode, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: mode == ThemeMode.dark,
              onChanged: AppThemeController.setDarkMode,
              secondary: Icon(
                mode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: AppColors.purple,
              ),
              title: const Text('Modo escuro'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({
    required this.onChangePassword,
    required this.onManageDevices,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onManageDevices;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfessionalSectionTitle(title: 'Segurança'),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onChangePassword,
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Alterar senha'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onManageDevices,
            icon: const Icon(Icons.devices_outlined),
            label: const Text('Gerenciar dispositivos'),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 16) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
