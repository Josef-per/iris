import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iris/core/supabase/supabase_config.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/daily_companion_repository.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/domain/daily_companion_message.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/domain/suggestion_feedback.dart';
import 'package:iris/features/ai_support/presentation/after_journal_support_sheet.dart';
import 'package:iris/features/ai_support/presentation/ai_support_hub_screen.dart';
import 'package:iris/features/ai_support/presentation/support_suggestion_screen.dart';
import 'package:iris/features/patient_dashboard/patient_today_summary.dart';
import 'package:iris/features/profile/profile_model.dart';
import 'package:iris/features/profile/profile_repository.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/diario_emocional_bottom_sheet.dart';
import 'package:iris/widgets/bottom_sheets/registro_alimentar_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.todayDataSource,
    this.onOpenReminders,
    this.onOpenSupportSuggestions,
    this.aiSupportStore,
    this.dailyCompanionDataSource,
  });

  final PatientTodayDataSource? todayDataSource;
  final VoidCallback? onOpenReminders;
  final VoidCallback? onOpenSupportSuggestions;
  final MockAiSupportStore? aiSupportStore;
  final DailyCompanionDataSource? dailyCompanionDataSource;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileRepository = ProfileRepository();
  late final Future<Profile?> _profileFuture;
  late final PatientTodayDataSource _todayDataSource;
  late Future<PatientTodaySummary> _todaySummaryFuture;
  late final DailyCompanionDataSource _dailyCompanionDataSource;
  late Future<DailyCompanionMessage> _dailyCompanionFuture;
  Set<String> _lastCompanionConsentSources = const <String>{};

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getCurrentUserProfile();
    _todayDataSource = widget.todayDataSource ?? PatientTodayRepository();
    _todaySummaryFuture = _todayDataSource.loadToday();
    _dailyCompanionDataSource =
        widget.dailyCompanionDataSource ??
        (SupabaseConfig.isConfigured
            ? SupabaseDailyCompanionRepository()
            : const DisabledDailyCompanionRepository());
    _dailyCompanionFuture = _dailyCompanionDataSource.loadToday();
    _lastCompanionConsentSources = _companionConsentSources();
    widget.aiSupportStore?.addListener(_onAiSupportStoreChanged);
  }

  @override
  void dispose() {
    widget.aiSupportStore?.removeListener(_onAiSupportStoreChanged);
    super.dispose();
  }

  Future<bool?> _openBottomSheet(Widget child) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );

    if (saved != null && mounted) {
      _refreshTodaySummary();
    }
    return saved;
  }

  Future<void> _openCheckInSheet() async {
    final saved = await _openBottomSheet(const CheckInDiarioBottomSheet());
    if (saved == true && mounted) {
      _refreshDailyCompanion();
      await _showAfterJournalSupport(
        AiSupportRecommendationTrigger.afterCheckIn,
      );
    }
  }

  Future<void> _openEmotionalDiarySheet() async {
    final saved = await _openBottomSheet(const DiarioEmocionalBottomSheet());
    if (saved == true && mounted) {
      _refreshDailyCompanion();
      await _showAfterJournalSupport(AiSupportRecommendationTrigger.afterDiary);
    }
  }

  Future<void> _showAfterJournalSupport(
    AiSupportRecommendationTrigger trigger,
  ) async {
    final store = widget.aiSupportStore;
    Future<SupportSuggestion?>? personalized;
    if (store != null && store.isOnboarded && store.isPersonalizationEnabled) {
      personalized = store.generatePersonalizedSuggestion(trigger: trigger);
    }
    await AfterJournalSupportSheet.show(
      context,
      personalizedSuggestion: personalized,
      onOpenPersonalized: _openPersonalizedSuggestion,
      onNotNow: () {
        if (personalized == null || store == null) return;
        unawaited(
          personalized.then((suggestion) {
            if (suggestion != null) {
              store.recordFeedback(
                SuggestionFeedbackType.dismissed,
                suggestion: suggestion,
              );
            }
          }),
        );
      },
      onClosedWithoutPersonalized: () {
        if (personalized == null || store == null) return;
        unawaited(
          personalized.then((suggestion) {
            if (suggestion != null) {
              store.cancelNotificationForSuggestion(suggestion);
            }
          }),
        );
      },
    );
  }

  void _openPersonalizedSuggestion(SupportSuggestion suggestion) {
    final store = widget.aiSupportStore;
    if (store == null) return;
    store.recordSuggestionOpenedInApp(suggestion);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportSuggestionScreen(
          store: store,
          suggestion: suggestion,
          onManageData: _openSupportSuggestions,
        ),
      ),
    );
  }

  void _openSupportSuggestions() {
    if (widget.onOpenSupportSuggestions case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiSupportHubScreen(store: widget.aiSupportStore),
      ),
    );
  }

  void _refreshTodaySummary() {
    setState(() {
      _todaySummaryFuture = _todayDataSource.loadToday();
    });
  }

  void _refreshDailyCompanion() {
    setState(() {
      _dailyCompanionFuture = _dailyCompanionDataSource.loadToday();
    });
  }

  Set<String> _companionConsentSources() {
    final store = widget.aiSupportStore;
    if (store == null || !store.isPersonalizationEnabled) {
      return const <String>{};
    }
    return store.consent.grantedSources.map((source) => source.name).toSet();
  }

  void _onAiSupportStoreChanged() {
    final sources = _companionConsentSources();
    if (setEquals(sources, _lastCompanionConsentSources)) return;
    _lastCompanionConsentSources = sources;
    // A persistencia das preferencias e assincrona. Pequeno atraso evita uma
    // leitura anterior a revogacao e remove do cartao qualquer texto derivado.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _refreshDailyCompanion();
    });
  }

  void _openImmediateSupport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SupportFlowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              padding: EdgeInsets.zero,
              child: AppResponsive(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                maxWidth: 960,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final greeting = _PatientGreeting(
                      profileFuture: _profileFuture,
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
              maxWidth: 960,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: FutureBuilder<DailyCompanionMessage>(
                        future: _dailyCompanionFuture,
                        builder: (context, snapshot) => _DailyCompanionCard(
                          companion: snapshot.data,
                          isLoading:
                              snapshot.connectionState ==
                              ConnectionState.waiting,
                          onManagePersonalization: _openSupportSuggestions,
                          onNeedSupport: _openImmediateSupport,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Registre seu dia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comece pelo check-in ou pelo diário emocional.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 840
                          ? 4
                          : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                      const gap = 14.0;
                      final availableWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      final width = columns == 1
                          ? constraints.maxWidth
                          : availableWidth.clamp(0, 300).toDouble();
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _ActionCard(
                            width: width,
                            icon: Icons.fact_check_outlined,
                            title: 'Check-in diário',
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
                          _ActionCard(
                            width: width,
                            icon: Icons.restaurant_menu_rounded,
                            title: 'Alimentação',
                            subtitle: 'Registre uma refeição e como se sentiu.',
                            onTap: () => _openBottomSheet(
                              const RegistroAlimentarBottomSheet(),
                            ),
                          ),
                          _ActionCard(
                            width: width,
                            icon: Icons.notifications_none_rounded,
                            title: 'Lembretes',
                            subtitle: 'Organize sua rotina sem cobranças.',
                            onTap: () {
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Apoio quando precisar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 840
                          ? 3
                          : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                      const gap = 14.0;
                      final availableWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      final cardWidth = columns == 1
                          ? constraints.maxWidth
                          : availableWidth.clamp(0, 300).toDouble();
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _SupportEntryCard(
                            key: const Key('home-not-ok-card'),
                            width: cardWidth,
                            icon: Icons.favorite_rounded,
                            title: 'Não estou bem',
                            subtitle: 'Encontre apoio e opções de segurança.',
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
                            title: 'Apoio para agora',
                            subtitle: 'Uma sugestão breve, do seu jeito.',
                            onTap: _openSupportSuggestions,
                          ),
                          _SupportEntryCard(
                            key: const Key('home-exercises-card'),
                            width: cardWidth,
                            icon: Icons.self_improvement_rounded,
                            title: 'Práticas breves',
                            subtitle: 'Escolha algo simples para este momento.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SupportFlowScreen(
                                  start: SupportFlowStart.catalog,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _DailyCompanionCard extends StatelessWidget {
  const _DailyCompanionCard({
    required this.companion,
    required this.isLoading,
    required this.onManagePersonalization,
    required this.onNeedSupport,
  });

  final DailyCompanionMessage? companion;
  final bool isLoading;
  final VoidCallback onManagePersonalization;
  final VoidCallback onNeedSupport;

  Future<void> _openReflectionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String? question,
    required bool personalized,
    required bool needsSupport,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('home-daily-companion-dialog'),
        icon: Icon(
          needsSupport ? Icons.favorite_rounded : Icons.auto_awesome_outlined,
        ),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
                if (question != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      question,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (personalized) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Feito apenas com o que você permitiu. Não substitui cuidado profissional.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          if (personalized && !needsSupport)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onManagePersonalization();
              },
              child: const Text('Ajustar personalização'),
            ),
          if (needsSupport)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                onNeedSupport();
              },
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Encontrar apoio'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsSupport = companion?.needsHumanSupport == true;
    final personalized = companion?.isPersonalized == true;
    final title = needsSupport
        ? 'Um cuidado importante agora'
        : 'Uma reflexão para você';
    final message =
        companion?.message ??
        (isLoading
            ? 'Preparando um espaço breve para você...'
            : 'Você não precisa resolver o dia inteiro agora. Qual seria um gesto pequeno de cuidado possível neste momento?');
    final question = companion?.reflectionQuestion;
    final background = needsSupport
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final foreground = needsSupport
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;
    final preview = isLoading
        ? 'Preparando uma reflexão breve...'
        : needsSupport
        ? 'Há opções de apoio disponíveis para este momento.'
        : 'Um convite breve para observar seu momento, no seu ritmo.';

    return Semantics(
      container: true,
      label: title,
      child: Container(
        key: const Key('home-daily-companion-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                needsSupport ? Icons.favorite_rounded : Icons.wb_sunny_outlined,
                color: foreground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          key: const Key('home-daily-companion-open'),
                          onPressed: () => _openReflectionDialog(
                            context,
                            title: title,
                            message: message,
                            question: question,
                            personalized: personalized,
                            needsSupport: needsSupport,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Ler reflexão'),
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                          ),
                        ),
                        if (needsSupport)
                          FilledButton.icon(
                            key: const Key('home-daily-companion-help'),
                            onPressed: onNeedSupport,
                            icon: const Icon(Icons.favorite_rounded),
                            label: const Text('Encontrar apoio agora'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    this.compact = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        height: compact ? 56 : 96,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: .18)),
        ),
        child: ExcludeSemantics(
          child: compact
              ? Row(
                  children: [
                    Icon(icon, color: AppColors.white, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(icon, color: AppColors.white, size: 21),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Center(
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
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
  const _PatientGreeting({required this.profileFuture});

  final Future<Profile?> profileFuture;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final cards = [
              _StatusCard(
                key: const Key('patient-today-meals'),
                icon: Icons.restaurant_rounded,
                value: values[0],
                label: 'Registros de alimentação',
                compact: compact,
              ),
              _StatusCard(
                key: const Key('patient-today-mood'),
                icon: Icons.favorite_outline_rounded,
                value: values[1],
                label: 'Como me senti',
                compact: compact,
              ),
              _StatusCard(
                key: const Key('patient-today-check-in'),
                icon: Icons.fact_check_outlined,
                value: values[2],
                label: 'Check-in de hoje',
                compact: compact,
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    cards[index],
                    if (index < cards.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
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
          border: highlighted ? null : Border.all(color: colors.outlineVariant),
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
                    color: highlighted ? AppColors.white : colors.primary,
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
        minHeight: 118,
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
