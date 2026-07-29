import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalSettingsView extends StatefulWidget {
  const ProfessionalSettingsView({super.key});

  @override
  State<ProfessionalSettingsView> createState() =>
      _ProfessionalSettingsViewState();
}

class _ProfessionalSettingsViewState extends State<ProfessionalSettingsView> {
  final _name = TextEditingController(text: 'Júlia Souza');
  final _email = TextEditingController(text: 'julia.souza@exemplo.com');
  final _phone = TextEditingController(text: '(11) 98765-4300');
  final _specialty = TextEditingController(
    text: 'Psiquiatria · Transtornos alimentares',
  );
  final _registration = TextEditingController(text: 'CRM/SP 123456');
  final _biography = TextEditingController(
    text:
        'Psiquiatra com atuação em saúde mental e transtornos alimentares, '
        'com foco em cuidado integrado e acompanhamento humanizado.',
  );
  final _clinic = TextEditingController(text: 'Clínica Horizonte');
  final _clinicAddress = TextEditingController(
    text: 'Av. Paulista, 1000 · São Paulo, SP',
  );

  bool _appointmentNotifications = true;
  bool _crisisAlerts = true;
  bool _automaticReports = false;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas localmente para visualização.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Perfil e configurações',
            subtitle: 'Gerencie seus dados profissionais e preferências',
            action: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.deepPurple,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar alterações'),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final profile = Column(
                  children: [
                    _ProfilePanel(
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
                    const _SecurityPanel(),
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
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.registration,
    required this.biography,
  });

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
          const ProfessionalSectionTitle(
            title: 'Informações profissionais',
            subtitle: 'Dados exibidos no acompanhamento dos pacientes',
          ),
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
                  child: const Text(
                    'JS',
                    style: TextStyle(
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
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _ResponsiveFields(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail profissional',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              TextField(
                controller: registration,
                decoration: const InputDecoration(
                  labelText: 'Registro profissional',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: specialty,
            decoration: const InputDecoration(
              labelText: 'Especialidade',
              prefixIcon: Icon(Icons.psychology_alt_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
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
          const ProfessionalSectionTitle(
            title: 'Dados da clínica',
            subtitle: 'Informações do local principal de atendimento',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: clinic,
            decoration: const InputDecoration(
              labelText: 'Nome da clínica',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: address,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
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
          const ProfessionalSectionTitle(
            title: 'Notificações e relatórios',
            subtitle: 'Escolha o que deseja acompanhar',
          ),
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
            subtitle: const Text('Prioridade alta para sinais de risco'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: automaticReports,
            onChanged: onReportsChanged,
            title: const Text('Relatórios automáticos'),
            subtitle: const Text('Resumo semanal por e-mail'),
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
          const ProfessionalSectionTitle(
            title: 'Aparência',
            subtitle: 'Personalize a visualização do painel',
          ),
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
              subtitle: const Text('Reduz o brilho em ambientes com pouca luz'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel();

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfessionalSectionTitle(
            title: 'Conta e segurança',
            subtitle: 'Senha e dispositivos conectados',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Alterar senha'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
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
