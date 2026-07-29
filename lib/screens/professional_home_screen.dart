import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/professional/professional_repository.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  final _authService = AuthService();
  final _professionalRepository = ProfessionalRepository();
  final _profileRepository = ProfileRepository();
  late Future<_ProfessionalHomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_ProfessionalHomeData> _loadHomeData() async {
    final profile = await _profileRepository.getCurrentUserProfile();
    final qrPayload = await _professionalRepository
        .getCurrentProfessionalQrPayload();
    final linkedPatients = await _professionalRepository.countLinkedPatients();
    return _ProfessionalHomeData(
      profile: profile,
      qrPayload: qrPayload,
      linkedPatients: linkedPatients,
    );
  }

  Future<void> _copyQrPayload(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código de vínculo copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppResponsive.isDesktop(context)
          ? null
          : Drawer(
              child: _ProfessionalNavigation(
                onSignOut: _authService.signOut,
                compact: false,
              ),
            ),
      body: Row(
        children: [
          if (AppResponsive.isDesktop(context))
            SizedBox(
              width: 260,
              child: _ProfessionalNavigation(
                onSignOut: _authService.signOut,
                compact: false,
              ),
            ),
          Expanded(
            child: FutureBuilder<_ProfessionalHomeData>(
              future: _homeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: AppErrorMessages.from(snapshot.error!),
                    onRetry: () =>
                        setState(() => _homeDataFuture = _loadHomeData()),
                  );
                }
                return _Dashboard(
                  data: snapshot.data!,
                  onCopyCode: _copyQrPayload,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data, required this.onCopyCode});
  final _ProfessionalHomeData data;
  final ValueChanged<String> onCopyCode;

  @override
  Widget build(BuildContext context) {
    final name = data.profile?.displayName.trim();
    final greeting = name == null || name.isEmpty ? 'Profissional' : name;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.porcelain.withValues(alpha: .94),
          surfaceTintColor: Colors.transparent,
          title: AppResponsive.isDesktop(context)
              ? null
              : const Text('Painel profissional'),
        ),
        SliverToBoxAdapter(
          child: AppResponsive(
            maxWidth: 1400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $greeting! 👋',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aqui está o resumo do seu acompanhamento.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth >= 1050
                        ? 4
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                    const gap = 16.0;
                    final width =
                        (constraints.maxWidth - gap * (count - 1)) / count;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _MetricCard(
                          width: width,
                          icon: Icons.people_alt_outlined,
                          value: '${data.linkedPatients}',
                          label: 'Pacientes vinculados',
                          supporting: 'Acompanhamento ativo',
                          color: AppColors.deepPurple,
                        ),
                        _MetricCard(
                          width: width,
                          icon: Icons.qr_code_2_rounded,
                          value: 'Ativo',
                          label: 'Código de vínculo',
                          supporting: 'Pronto para compartilhar',
                          color: AppColors.purple,
                        ),
                        _MetricCard(
                          width: width,
                          icon: Icons.favorite_outline_rounded,
                          value: 'Hoje',
                          label: 'Última sincronização',
                          supporting: 'Dados atualizados',
                          color: AppColors.success,
                        ),
                        _MetricCard(
                          width: width,
                          icon: Icons.notifications_none_rounded,
                          value: '0',
                          label: 'Alertas pendentes',
                          supporting: 'Tudo tranquilo',
                          color: AppColors.danger,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final qr = _QrPanel(
                      payload: data.qrPayload,
                      onCopy: () => onCopyCode(data.qrPayload),
                    );
                    final overview = const _OverviewPanel();
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: overview),
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: qr),
                            ],
                          )
                        : Column(
                            children: [
                              overview,
                              const SizedBox(height: 20),
                              qr,
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfessionalNavigation extends StatelessWidget {
  const _ProfessionalNavigation({
    required this.onSignOut,
    required this.compact,
  });
  final VoidCallback onSignOut;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/Login.png',
                width: 150,
                height: 82,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              const _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Visão geral',
                selected: true,
              ),
              const _NavItem(
                icon: Icons.people_alt_outlined,
                label: 'Pacientes',
              ),
              const _NavItem(
                icon: Icons.auto_stories_outlined,
                label: 'Anotações',
              ),
              const _NavItem(
                icon: Icons.health_and_safety_outlined,
                label: 'Plano de cuidado',
              ),
              const _NavItem(
                icon: Icons.settings_outlined,
                label: 'Configurações',
              ),
              const Spacer(),
              const Divider(color: Color(0x33FFFFFF)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.white.withValues(alpha: .14) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.white),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.supporting,
    required this.color,
  });
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final String supporting;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppSurface(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    supporting,
                    style: TextStyle(color: color, fontSize: 12),
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

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acesso rápido', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Centralize o acompanhamento dos seus pacientes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _QuickAction(
            icon: Icons.people_alt_outlined,
            title: 'Gerenciar pacientes',
            subtitle: 'Consulte vínculos e acompanhe registros recentes.',
          ),
          const Divider(height: 28),
          const _QuickAction(
            icon: Icons.note_alt_outlined,
            title: 'Anotações clínicas',
            subtitle: 'Organize observações importantes do acompanhamento.',
          ),
          const Divider(height: 28),
          const _QuickAction(
            icon: Icons.health_and_safety_outlined,
            title: 'Planos de cuidado',
            subtitle: 'Revise metas, lembretes e orientações.',
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepPurple),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.payload, required this.onCopy});
  final String payload;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        children: [
          Text(
            'Vincular paciente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Peça ao paciente para escanear este código.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lavender),
            ),
            child: QrImageView(
              data: payload,
              size: 190,
              backgroundColor: AppColors.white,
              eyeStyle: const QrEyeStyle(color: AppColors.ink),
              dataModuleStyle: const QrDataModuleStyle(color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar código'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppResponsive(
        maxWidth: 520,
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: AppColors.deepPurple,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalHomeData {
  const _ProfessionalHomeData({
    required this.profile,
    required this.qrPayload,
    required this.linkedPatients,
  });
  final Profile? profile;
  final String qrPayload;
  final int linkedPatients;
}
