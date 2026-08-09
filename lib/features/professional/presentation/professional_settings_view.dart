import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalSettingsView extends StatefulWidget {
  const ProfessionalSettingsView({
    super.key,
    required this.store,
    this.onDirtyChanged,
  });

  final ProfessionalFrontendStore store;
  final ValueChanged<bool>? onDirtyChanged;

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
  var _saving = false;
  var _dirty = false;

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
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  List<TextEditingController> get _controllers => [
    _name,
    _email,
    _phone,
    _specialty,
    _registration,
    _biography,
    _clinic,
    _clinicAddress,
  ];

  void _markDirty() {
    if (!mounted || _saving || _dirty) return;
    setState(() => _dirty = true);
    widget.onDirtyChanged?.call(true);
  }

  void _change(VoidCallback change) {
    final wasDirty = _dirty;
    setState(() {
      change();
      _dirty = true;
    });
    if (!wasDirty) widget.onDirtyChanged?.call(true);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_dirty || !_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.store.updateSettings(
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
      if (!mounted) return;
      _email.text = widget.store.settings.email;
      setState(() => _dirty = false);
      widget.onDirtyChanged?.call(false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.store.isConnected
                  ? 'Configurações salvas.'
                  : 'Configurações salvas nesta sessão.',
            ),
          ),
        );
    } catch (error) {
      if (mounted) {
        if (error is ProfessionalSettingsPartialUpdateException) {
          _email.text = widget.store.settings.email;
        }
        showProfessionalOperationError(context, error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAvatar() async {
    final value = await showProfessionalTextItemForm(
      context,
      title: 'Foto do perfil',
      label: 'Iniciais',
      initialValue: _avatarInitials,
    );
    if (value == null) return;
    _change(
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
            subtitle: _dirty
                ? 'Dados e preferências · Alterações não salvas'
                : 'Dados e preferências',
            action: FilledButton.icon(
              onPressed: _saving || !_dirty ? null : _save,
              style: AppButtonStyles.onBrandFilled,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Salvando...'
                    : _dirty
                    ? 'Salvar'
                    : 'Salvo',
              ),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  final profile = ProfessionalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const _SettingsDivider(),
                        _ClinicPanel(clinic: _clinic, address: _clinicAddress),
                      ],
                    ),
                  );
                  final preferences = ProfessionalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NotificationsPanel(
                          appointmentNotifications: _appointmentNotifications,
                          crisisAlerts: _crisisAlerts,
                          automaticReports: _automaticReports,
                          onAppointmentChanged: (value) =>
                              _change(() => _appointmentNotifications = value),
                          onCrisisChanged: (value) =>
                              _change(() => _crisisAlerts = value),
                          onReportsChanged: (value) =>
                              _change(() => _automaticReports = value),
                        ),
                        const _SettingsDivider(),
                        const _AppearancePanel(),
                        const _SettingsDivider(),
                        _SecurityPanel(
                          onChangePassword: _changePassword,
                          onManageDevices: _showDevices,
                        ),
                      ],
                    ),
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
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => ProfessionalResponsiveDialog(
          title: 'Alterar senha',
          maxWidth: 420,
          canClose: !saving,
          content: Form(
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
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await widget.store.changePassword(
                          currentPassword: current.text,
                          newPassword: password.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (!context.mounted) return;
                        setDialogState(() => saving = false);
                        showProfessionalOperationError(context, error);
                      }
                    },
              child: Text(saving ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
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
      useRootNavigator: false,
      builder: (context) => ProfessionalResponsiveDialog(
        title: 'Dispositivos',
        maxWidth: 420,
        content: const Text(
          'A lista de sessões não está disponível. Use “Sair” para encerrar esta sessão.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
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
    return Column(
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  avatarInitials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    );
  }
}

class _ClinicPanel extends StatelessWidget {
  const _ClinicPanel({required this.clinic, required this.address});

  final TextEditingController clinic;
  final TextEditingController address;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfessionalSectionTitle(title: 'Notificações'),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: appointmentNotifications,
          onChanged: onAppointmentChanged,
          title: const Text('Lembretes de consultas'),
          subtitle: const Text('Avisos antes dos próximos atendimentos'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: crisisAlerts,
          onChanged: onCrisisChanged,
          title: const Text('Alertas de crise'),
          subtitle: const Text('Notificações para sinais de atenção'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: automaticReports,
          onChanged: onReportsChanged,
          title: const Text('Relatórios automáticos'),
          subtitle: const Text('Resumos periódicos de acompanhamento'),
        ),
      ],
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
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
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Modo escuro'),
            subtitle: const Text('Reduz o brilho das superfícies'),
          ),
        ),
      ],
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
    return Column(
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
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
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
