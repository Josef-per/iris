import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/widgets/app_responsive.dart';

class AiSupportOnboardingScreen extends StatefulWidget {
  const AiSupportOnboardingScreen({
    super.key,
    required this.store,
    this.onFinished,
    this.onBack,
  });

  final MockAiSupportStore store;
  final VoidCallback? onFinished;
  final VoidCallback? onBack;

  @override
  State<AiSupportOnboardingScreen> createState() =>
      _AiSupportOnboardingScreenState();
}

class _AiSupportOnboardingScreenState extends State<AiSupportOnboardingScreen> {
  var _step = 0;
  var _isFinishing = false;
  late bool _personalizationEnabled;
  late Set<SupportSignalSource> _sources;
  late Set<SupportSuggestionCategory> _categories;
  late Set<SupportContentTag> _excludedContentTags;
  late bool _notificationsEnabled;
  late NotificationFrequency _frequency;
  late LockScreenPreview _lockScreenPreview;
  late Set<int> _allowedWeekdays;
  late int _startHour;
  late int _endHour;

  @override
  void initState() {
    super.initState();
    final consent = widget.store.consent;
    final preferences = widget.store.preferences;
    final notifications = preferences.notifications;
    _personalizationEnabled =
        consent.personalizedSuggestionsGranted &&
        preferences.personalizedSuggestionsEnabled;
    _sources = {...consent.grantedSources};
    _categories = {...preferences.allowedCategories};
    _excludedContentTags = {...preferences.excludedContentTags};
    _notificationsEnabled = _personalizationEnabled && notifications.enabled;
    _frequency = notifications.frequency;
    _lockScreenPreview = notifications.lockScreenPreview;
    _allowedWeekdays = {...notifications.window.allowedWeekdays};
    _startHour = notifications.window.start.hour;
    _endHour = notifications.window.end.hour;
  }

  bool get _canContinue =>
      !_personalizationEnabled ||
      (hasPrimaryPatientSupportSource(_sources) && _categories.isNotEmpty);

  Future<void> _next() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else if (widget.onBack case final callback?) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _finish() async {
    if (_isFinishing || !_canContinue) return;
    setState(() => _isFinishing = true);
    final endHour = _endHour == _startHour ? (_endHour + 1) % 24 : _endHour;
    var notificationsEnabled = _notificationsEnabled;
    if (notificationsEnabled && !widget.store.isDemonstration) {
      final permission = await widget.store.requestNotificationPermission();
      notificationsEnabled = permission.allowsScheduling;
    }
    if (!mounted) return;

    widget.store.completeOnboarding(
      consent: AiSupportConsent(
        personalizedSuggestionsGranted: _personalizationEnabled,
        grantedSources: _personalizationEnabled
            ? _sources
            : const <SupportSignalSource>{},
      ),
      preferences: AiSupportPreferences(
        personalizedSuggestionsEnabled: _personalizationEnabled,
        allowedCategories: _categories,
        maximumExerciseMinutes: 2,
        excludedContentTags: _excludedContentTags,
        notifications: NotificationPreferences(
          enabled: notificationsEnabled,
          frequency: notificationsEnabled
              ? _frequency
              : NotificationFrequency.never,
          window: NotificationWindow(
            start: SupportTimeOfDay(_startHour),
            end: SupportTimeOfDay(endHour),
            allowedWeekdays: _allowedWeekdays,
          ),
          lockScreenPreview: _lockScreenPreview,
          soundEnabled: false,
          vibrationEnabled: false,
        ),
      ),
    );
    if (_notificationsEnabled && !notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Os lembretes não foram ativados. O apoio continua disponível no app.',
          ),
        ),
      );
    }
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _step == 0 ? 'Voltar' : 'Etapa anterior',
          onPressed: _isFinishing ? null : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Apoio para você'),
      ),
      body: AppResponsive(
        maxWidth: 700,
        child: ListView(
          children: [
            Text('Etapa ${_step + 1} de 2', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (_step + 1) / 2),
            const SizedBox(height: 24),
            if (_step == 0)
              _DataStep(
                personalizationEnabled: _personalizationEnabled,
                sources: _sources,
                onPersonalizationChanged: (enabled) {
                  setState(() {
                    _personalizationEnabled = enabled;
                    if (!enabled) {
                      _sources.clear();
                      _notificationsEnabled = false;
                    } else if (_categories.isEmpty) {
                      _categories.addAll(patientAvailableSupportCategories);
                    }
                  });
                },
                onSourceChanged: (source, enabled) {
                  setState(() {
                    enabled ? _sources.add(source) : _sources.remove(source);
                  });
                },
              )
            else
              _PreferenceStep(
                personalizationEnabled: _personalizationEnabled,
                categories: _categories,
                excludedContentTags: _excludedContentTags,
                notificationsEnabled: _notificationsEnabled,
                frequency: _frequency,
                lockScreenPreview: _lockScreenPreview,
                allowedWeekdays: _allowedWeekdays,
                startHour: _startHour,
                endHour: _endHour,
                onCategoryChanged: (category, enabled) {
                  setState(() {
                    enabled
                        ? _categories.add(category)
                        : _categories.remove(category);
                  });
                },
                onBreathingChanged: (avoid) {
                  setState(() {
                    avoid
                        ? _excludedContentTags.add(
                            SupportContentTag.breathingFocused,
                          )
                        : _excludedContentTags.remove(
                            SupportContentTag.breathingFocused,
                          );
                  });
                },
                onNotificationsChanged: (enabled) {
                  setState(() {
                    _notificationsEnabled = enabled;
                    if (enabled && _frequency == NotificationFrequency.never) {
                      _frequency = NotificationFrequency.oncePerWeek;
                    }
                  });
                },
                onFrequencyChanged: (value) =>
                    setState(() => _frequency = value),
                onPreviewChanged: (value) =>
                    setState(() => _lockScreenPreview = value),
                onDayChanged: (day, enabled) {
                  setState(() {
                    enabled
                        ? _allowedWeekdays.add(day)
                        : _allowedWeekdays.remove(day);
                    if (_allowedWeekdays.isEmpty) _allowedWeekdays.add(day);
                  });
                },
                onStartHourChanged: (hour) => setState(() => _startHour = hour),
                onEndHourChanged: (hour) => setState(() => _endHour = hour),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: Key('ai-support-onboarding-next-$_step'),
              onPressed: _isFinishing || !_canContinue ? null : _next,
              icon: _isFinishing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _step == 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(_step == 1 ? 'Concluir' : 'Continuar'),
            ),
            const SizedBox(height: 10),
            Text(
              'Você pode mudar ou desligar tudo depois.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataStep extends StatelessWidget {
  const _DataStep({
    required this.personalizationEnabled,
    required this.sources,
    required this.onPersonalizationChanged,
    required this.onSourceChanged,
  });

  final bool personalizationEnabled;
  final Set<SupportSignalSource> sources;
  final ValueChanged<bool> onPersonalizationChanged;
  final void Function(SupportSignalSource source, bool enabled) onSourceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apoio breve, sob seu controle',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        const Text(
          'Não é terapia nem monitoramento de crise. A Íris não avisa ninguém e você escolhe exatamente o que pode ser considerado.',
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          key: const Key('ai-support-personalization-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Personalizar para mim'),
          subtitle: const Text('Você escolhe quais dados a Íris pode considerar.'),
          value: personalizationEnabled,
          onChanged: onPersonalizationChanged,
        ),
        if (personalizationEnabled) ...[
          const SizedBox(height: 10),
          Text('O que posso considerar?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final source in patientAvailableSupportSources)
                FilterChip(
                  key: Key('ai-support-source-${source.name}'),
                  label: Text(_shortSourceLabel(source)),
                  selected: sources.contains(source),
                  onSelected: (enabled) => onSourceChanged(source, enabled),
              ),
            ],
          ),
          if (sources.contains(SupportSignalSource.diaryText)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Ao escolher Meu diário (texto livre), uma entrada recente pode ser usada no servidor para criar uma reflexão de hoje. Não é diagnóstico nem monitoramento, e você pode desligar ou excluir esse dado derivado quando quiser.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (!hasPrimaryPatientSupportSource(sources)) ...[
            const SizedBox(height: 10),
            Text(
              sources.isEmpty
                  ? 'Escolha pelo menos uma opção.'
                  : 'Escolha Meus check-ins, Temas que eu marcar ou Meu diário para ter um ponto de partida.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ],
    );
  }
}

class _PreferenceStep extends StatelessWidget {
  const _PreferenceStep({
    required this.personalizationEnabled,
    required this.categories,
    required this.excludedContentTags,
    required this.notificationsEnabled,
    required this.frequency,
    required this.lockScreenPreview,
    required this.allowedWeekdays,
    required this.startHour,
    required this.endHour,
    required this.onCategoryChanged,
    required this.onBreathingChanged,
    required this.onNotificationsChanged,
    required this.onFrequencyChanged,
    required this.onPreviewChanged,
    required this.onDayChanged,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
  });

  final bool personalizationEnabled;
  final Set<SupportSuggestionCategory> categories;
  final Set<SupportContentTag> excludedContentTags;
  final bool notificationsEnabled;
  final NotificationFrequency frequency;
  final LockScreenPreview lockScreenPreview;
  final Set<int> allowedWeekdays;
  final int startHour;
  final int endHour;
  final void Function(SupportSuggestionCategory category, bool enabled)
  onCategoryChanged;
  final ValueChanged<bool> onBreathingChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<NotificationFrequency> onFrequencyChanged;
  final ValueChanged<LockScreenPreview> onPreviewChanged;
  final void Function(int day, bool enabled) onDayChanged;
  final ValueChanged<int> onStartHourChanged;
  final ValueChanged<int> onEndHourChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como prefere receber apoio?',
          style: theme.textTheme.headlineSmall,
        ),
        if (personalizationEnabled) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in patientAvailableSupportCategories)
                FilterChip(
                  key: Key('ai-support-category-${category.name}'),
                  label: Text(category.label),
                  selected: categories.contains(category),
                  onSelected: (enabled) => onCategoryChanged(category, enabled),
                ),
            ],
          ),
          SwitchListTile.adaptive(
            key: const Key('ai-support-avoid-breathing-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Evitar práticas focadas na respiração'),
            value: excludedContentTags.contains(
              SupportContentTag.breathingFocused,
            ),
            onChanged: onBreathingChanged,
          ),
        ] else
          const Text('Você poderá usar práticas mesmo sem personalização.'),
        if (personalizationEnabled) ...[
          const Divider(height: 28),
          SwitchListTile.adaptive(
            key: const Key('ai-support-notification-simulator-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Receber lembretes discretos'),
            subtitle: const Text('Sem som, vibração ou detalhes pessoais.'),
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
        ],
        if (personalizationEnabled && notificationsEnabled)
          ExpansionTile(
            key: const Key('ai-support-advanced-notification-settings'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Horários e privacidade'),
            subtitle: const Text('Opcional'),
            children: [
              DropdownButtonFormField<NotificationFrequency>(
                key: const Key('ai-support-frequency-field'),
                decoration: const InputDecoration(labelText: 'No máximo'),
                initialValue: frequency,
                items: NotificationFrequency.values
                    .where((value) => value != NotificationFrequency.never)
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onFrequencyChanged(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LockScreenPreview>(
                key: const Key('ai-support-preview-field'),
                decoration: const InputDecoration(labelText: 'Tela bloqueada'),
                initialValue: lockScreenPreview,
                items: LockScreenPreview.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onPreviewChanged(value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HourField(
                      label: 'A partir de',
                      value: startHour,
                      onChanged: onStartHourChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HourField(
                      label: 'Até',
                      value: endHour,
                      onChanged: onEndHourChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List<Widget>.generate(7, (index) {
                  final day = index + DateTime.monday;
                  return FilterChip(
                    label: Text(_weekdayLabel(day)),
                    selected: allowedWeekdays.contains(day),
                    onSelected: (selected) => onDayChanged(day, selected),
                  );
                }),
              ),
              const SizedBox(height: 14),
              _GenericPreview(preview: lockScreenPreview),
              const SizedBox(height: 8),
            ],
          ),
      ],
    );
  }
}

class _HourField extends StatelessWidget {
  const _HourField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: label),
      initialValue: value,
      items: List<DropdownMenuItem<int>>.generate(
        24,
        (hour) => DropdownMenuItem(value: hour, child: Text('$hour:00')),
      ),
      onChanged: (hour) {
        if (hour != null) onChanged(hour);
      },
    );
  }
}

class _GenericPreview extends StatelessWidget {
  const _GenericPreview({required this.preview});

  final LockScreenPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('ai-support-generic-preview'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        preview == LockScreenPreview.generic
            ? MockSupportTemplateCatalog.genericNotifications.first.text
            : 'Sem texto da sugestão na tela bloqueada.',
      ),
    );
  }
}

String _shortSourceLabel(SupportSignalSource source) => switch (source) {
  SupportSignalSource.moodHistory => 'Meus check-ins',
  SupportSignalSource.diaryTags => 'Temas que eu marcar',
  SupportSignalSource.diaryText => 'Meu diário (texto livre)',
  SupportSignalSource.exerciseFeedback => 'Práticas que avaliei',
  SupportSignalSource.notificationInteractions => 'Lembretes que abri',
};

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Seg',
  DateTime.tuesday => 'Ter',
  DateTime.wednesday => 'Qua',
  DateTime.thursday => 'Qui',
  DateTime.friday => 'Sex',
  DateTime.saturday => 'Sáb',
  DateTime.sunday => 'Dom',
  _ => '',
};
