import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/presentation/after_journal_support_sheet.dart';
import 'package:iris/features/ai_support/presentation/ai_support_hub_screen.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';
import 'package:iris/screens/patient_history_screen.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.todayDataSource,
    this.onOpenReminders,
    this.onOpenCarePlan,
    this.onOpenHistory,
    this.onOpenSupportSuggestions,
  });

  final PatientTodayDataSource? todayDataSource;
  final VoidCallback? onOpenReminders;
  final VoidCallback? onOpenCarePlan;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenSupportSuggestions;

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

  Future<bool> _openBottomSheet(Widget child) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );

    if (saved == true && mounted) {
      _refreshTodaySummary();
    }
    return saved == true;
  }

  Future<void> _openCheckInSheet() async {
    final saved = await _openBottomSheet(const CheckInDiarioBottomSheet());
    if (saved && mounted) {
      await AfterJournalSupportSheet.show(context);
    }
  }

  Future<void> _openEmotionalDiarySheet() async {
    final saved = await _openBottomSheet(const DiarioEmocionalBottomSheet());
    if (saved && mounted) {
      await AfterJournalSupportSheet.show(context);
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
      // O Supabase remove a sessão local antes de tentar invalidar o token no
      // servidor. Se a tela ainda existir, a falha ocorreu antes da transição.
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
                  if (widget.onOpenCarePlan case final callback?) {
                    callback();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientCarePlanScreen(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Meu histórico'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (widget.onOpenHistory case final callback?) {
                    callback();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientHistoryScreen(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                key: const Key('home-support-suggestions-menu'),
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Sugestões de apoio'),
                subtitle: const Text('Demonstração local e controlável'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (widget.onOpenSupportSuggestions case final callback?) {
                    callback();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiSupportHubScreen(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('Lembretes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (widget.onOpenReminders case final callback?) {
                    callback();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LembretesScreen(),
                      ),
                    );
                  }
                },
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final greeting = _PatientGreeting(
                      profileFuture: _profileFuture,
                      onOpenMenu: _openMenu,
                    );
                    final status = FutureBuilder<PatientTodaySummary>(
                      future: _todaySummaryFuture,
                      builder: (context, snapshot) => _TodayStatusCards(
                        summary: snapshot.data,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        error: snapshot.error,
                        onRetry: _refreshTodaySummary,
                      ),
                    );

                    if (constraints.maxWidth >= 820) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: greeting),
                          const SizedBox(width: 48),
                          SizedBox(width: 560, child: status),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [greeting, const SizedBox(height: 28), status],
                    );
                  },
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 700;
                      final cardWidth = wide
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _SupportEntryCard(
                            key: const Key('home-exercises-card'),
                            width: cardWidth,
                            icon: Icons.self_improvement_rounded,
                            title: 'Exercícios',
                            subtitle: 'Práticas curtas para diferentes momentos.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SupportFlowScreen(
                                  start: SupportFlowStart.catalog,
                                ),
                              ),
                            ),
                          ),
                          _SupportEntryCard(
                            key: const Key('home-not-ok-card'),
                            width: cardWidth,
                            icon: Icons.favorite_rounded,
                            title: 'Não estou bem',
                            subtitle: 'Encontre uma prática ou procure apoio.',
                            highlighted: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SupportFlowScreen(),
                              ),
                            ),
                          ),
                          _SupportEntryCard(
                            key: const Key('home-support-suggestions-card'),
                            width: cardWidth,
                            icon: Icons.auto_awesome_outlined,
                            title: 'Sugestões de apoio',
                            subtitle:
                                'Uma demonstração local, discreta e opcional.',
                            onTap: () {
                              if (widget.onOpenSupportSuggestions
                                  case final callback?) {
                                callback();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AiSupportHubScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Cuidar de você hoje',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escolha uma atividade para registrar como foi o seu dia.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 800
                          ? 3
                          : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                      const gap = 14.0;
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
                            subtitle: 'Registre uma refeição e como se sentiu.',
                            onTap: () => _openBottomSheet(
                              const RegistroAlimentarBottomSheet(),
                            ),
                          ),
                          _ActionCard(
                            width: width,
                            icon: Icons.fact_check_outlined,
                            title: 'Registro do dia',
                            subtitle:
                                'Faça uma pausa e perceba como você está.',
                            onTap: _openCheckInSheet,
                          ),
                          _ActionCard(
                            width: width,
                            icon: Icons.favorite_outline_rounded,
                            title: 'Diário emocional',
                            subtitle: 'Dê nome ao que você está sentindo.',
                            onTap: _openEmotionalDiarySheet,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mensagem do dia',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Você não precisa resolver tudo de uma vez. Cada pequeno passo já é um avanço. Seja gentil com você — um dia de cada vez já é suficiente.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                            height: 1.45,
                          ),
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
    return Semantics(
      label: '$label: $value',
      child: Container(
        height: 106,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: .18)),
        ),
        child: ExcludeSemantics(
          child: Column(
            children: [
              Icon(icon, color: AppColors.white, size: 22),
              const SizedBox(height: 7),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientGreeting extends StatelessWidget {
  const _PatientGreeting({
    required this.profileFuture,
    required this.onOpenMenu,
  });

  final Future<Profile?> profileFuture;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FutureBuilder<Profile?>(
            future: profileFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.displayName.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name == null || name.isEmpty ? 'Olá!' : 'Olá, $name!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Como você está se sentindo hoje?',
                    style: TextStyle(color: AppColors.white),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: 'Abrir menu',
          onPressed: onOpenMenu,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            backgroundColor: AppColors.white.withValues(alpha: .14),
            foregroundColor: AppColors.white,
          ),
          icon: const Icon(Icons.grid_view_rounded),
        ),
      ],
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
                label: 'Registro do dia',
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

class _SupportEntryCard extends StatelessWidget {
  const _SupportEntryCard({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Card “Não estou bem”: roxo profundo da marca, sem sirene.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = highlighted ? AppColors.white : colors.onSurface;
    final iconBackground = highlighted
        ? AppColors.white.withValues(alpha: .16)
        : colors.primaryContainer;
    final iconForeground = highlighted
        ? AppColors.white
        : colors.onPrimaryContainer;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width,
        maxWidth: width,
        minHeight: 110,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: highlighted ? AppColors.brandGradient : null,
          color: highlighted ? null : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: highlighted
              ? null
              : Border.all(color: colors.outlineVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconForeground),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: highlighted ? AppColors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: highlighted
                        ? AppColors.white
                        : colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width,
        maxWidth: width,
        minHeight: 150,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
