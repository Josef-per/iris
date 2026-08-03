import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.todayDataSource});

  final PatientTodayDataSource? todayDataSource;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _profileRepository = ProfileRepository();
  late final Future<Profile?> _profileFuture;
  late final PatientTodayDataSource _todayDataSource;
  late Future<PatientTodaySummary> _todaySummaryFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getCurrentUserProfile();
    _todayDataSource = widget.todayDataSource ?? PatientTodayRepository();
    _todaySummaryFuture = _todayDataSource.loadToday();
  }

  Future<void> _openBottomSheet(Widget child) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );

    if (saved == true && mounted) {
      _refreshTodaySummary();
    }
  }

  void _refreshTodaySummary() {
    setState(() {
      _todaySummaryFuture = _todayDataSource.loadToday();
    });
  }

  Future<void> _signOut(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    try {
      await _authService.signOut();
    } catch (error) {
      // O Supabase remove a sessao local antes de tentar invalidar o token no
      // servidor. Se a tela ainda existir, a falha ocorreu antes da transicao.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Plano de cuidado'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PatientCarePlanScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('Lembretes'),
                subtitle: const Text('Em breve'),
                enabled: false,
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sair da conta'),
                textColor: AppColors.danger,
                iconColor: AppColors.danger,
                onTap: () => _signOut(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              child: AppResponsive(
                padding: EdgeInsets.zero,
                maxWidth: 1120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 52),
                              child: FutureBuilder<Profile?>(
                                future: _profileFuture,
                                builder: (context, snapshot) {
                                  final name = snapshot.data?.displayName
                                      .trim();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name == null || name.isEmpty
                                            ? 'Olá!'
                                            : 'Olá, $name!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(color: AppColors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Como você está se sentindo hoje?',
                                        style: TextStyle(
                                          color: AppColors.lavender,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton.filledTonal(
                                tooltip: 'Abrir menu',
                                onPressed: _openMenu,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.white.withValues(
                                    alpha: .14,
                                  ),
                                  foregroundColor: AppColors.white,
                                ),
                                icon: const Icon(Icons.grid_view_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: FutureBuilder<PatientTodaySummary>(
                          future: _todaySummaryFuture,
                          builder: (context, snapshot) => _TodayStatusCards(
                            summary: snapshot.data,
                            isLoading:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                            error: snapshot.error,
                            onRetry: _refreshTodaySummary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppResponsive(
              maxWidth: 1120,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSurface(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 620
                            ? 3
                            : constraints.maxWidth >= 480
                            ? 2
                            : 1;
                        const gap = 16.0;
                        final width =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _ActionCard(
                              width: width,
                              icon: Icons.restaurant_menu_rounded,
                              title: 'Registro de alimentação',
                              subtitle:
                                  'Registre uma refeição e como se sentiu.',
                              colors: const [
                                AppColors.lavender,
                                AppColors.purple,
                              ],
                              onTap: () => _openBottomSheet(
                                const RegistroAlimentarBottomSheet(),
                              ),
                            ),
                            _ActionCard(
                              width: width,
                              icon: Icons.auto_stories_rounded,
                              title: 'Check-in diário',
                              subtitle: 'Faça uma pausa e avalie o seu dia.',
                              colors: const [AppColors.purple, AppColors.ink],
                              onTap: () => _openBottomSheet(
                                const CheckInDiarioBottomSheet(),
                              ),
                            ),
                            _ActionCard(
                              width: width,
                              icon: Icons.favorite_rounded,
                              title: 'Diário emocional',
                              subtitle: 'Dê nome ao que você está sentindo.',
                              colors: const [
                                AppColors.purple,
                                AppColors.deepPurple,
                              ],
                              onTap: () => _openBottomSheet(
                                const DiarioEmocionalBottomSheet(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: AppColors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mensagem do dia',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Você não precisa resolver tudo de uma vez. Cada pequeno passo já é um avanço. Seja gentil com você — um dia de cada vez já é suficiente.',
                          style: TextStyle(color: AppColors.ink, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(color: AppColors.lavender, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStatusCards extends StatelessWidget {
  const _TodayStatusCards({
    required this.summary,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final PatientTodaySummary? summary;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final values = isLoading
        ? const ['…', '…', '…']
        : error != null
        ? const ['—', '—', '—']
        : [
            summary?.mealCount.toString() ?? '0',
            summary?.moodLabel ?? 'Sem registro',
            summary?.checkInLabel ?? 'Pendente',
          ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                key: const Key('patient-today-meals'),
                icon: Icons.restaurant_rounded,
                value: values[0],
                label: 'Refeições hoje',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusCard(
                key: const Key('patient-today-mood'),
                icon: Icons.favorite_outline_rounded,
                value: values[1],
                label: 'Humor hoje',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusCard(
                key: const Key('patient-today-check-in'),
                icon: Icons.fact_check_outlined,
                value: values[2],
                label: 'Check-in',
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('patient-today-retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Não foi possível carregar. Tentar novamente'),
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width < 240 ? 220 : 210,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: AppColors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
