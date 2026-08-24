import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Onboarding local para a demonstração de sugestões de apoio.
///
/// A tela não pede permissões do aparelho e só usa os estados selecionados
/// aqui. Texto livre do diário não é uma fonte disponível.
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
    _notificationsEnabled = notifications.enabled;
    _frequency = notifications.frequency;
    _lockScreenPreview = notifications.lockScreenPreview;
    _allowedWeekdays = {...notifications.window.allowedWeekdays};
    _startHour = notifications.window.start.hour;
    _endHour = notifications.window.end.hour;
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
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

  void _finish() {
    final endHour = _endHour == _startHour ? (_endHour + 1) % 24 : _endHour;
    final notificationPreferences = NotificationPreferences(
      enabled: _notificationsEnabled,
      frequency: _notificationsEnabled
          ? _frequency
          : NotificationFrequency.never,
      window: NotificationWindow(
        start: SupportTimeOfDay(_startHour),
        end: SupportTimeOfDay(endHour),
        allowedWeekdays: _allowedWeekdays,
      ),
      lockScreenPreview: _lockScreenPreview,
      // Esta categoria começa discreta: nunca ativamos som ou vibração aqui.
      soundEnabled: false,
      vibrationEnabled: false,
    );
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
        notifications: notificationPreferences,
      ),
    );
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _step == 0 ? 'Voltar' : 'Etapa anterior',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Sugestões de apoio'),
      ),
      body: AppResponsive(
        maxWidth: 720,
        child: ListView(
          children: [
            Semantics(
              liveRegion: true,
              label: 'Etapa ${_step + 1} de 3',
              child: Text(
                'Etapa ${_step + 1} de 3',
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_step + 1) / 3),
            const SizedBox(height: 28),
            switch (_step) {
              0 => _LimitsStep(theme: theme),
              1 => _ConsentStep(
                personalizationEnabled: _personalizationEnabled,
                sources: _sources,
                onPersonalizationChanged: (value) {
                  setState(() {
                    _personalizationEnabled = value;
                    if (!value) _sources.clear();
                  });
                },
                onSourceChanged: (source, enabled) {
                  setState(() {
                    enabled ? _sources.add(source) : _sources.remove(source);
                  });
                },
              ),
              _ => _PreferencesStep(
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
                onFrequencyChanged: (frequency) {
                  setState(() => _frequency = frequency);
                },
                onPreviewChanged: (preview) {
                  setState(() => _lockScreenPreview = preview);
                },
                onDayChanged: (day, enabled) {
                  setState(() {
                    enabled
                        ? _allowedWeekdays.add(day)
                        : _allowedWeekdays.remove(day);
                  });
                },
                onStartHourChanged: (hour) {
                  setState(() => _startHour = hour);
                },
                onEndHourChanged: (hour) {
                  setState(() => _endHour = hour);
                },
              ),
            },
            const SizedBox(height: 28),
            FilledButton.icon(
              key: Key('ai-support-onboarding-next-$_step'),
              onPressed: _next,
              icon: Icon(
                _step == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
              ),
              label: Text(_step == 2 ? 'Concluir' : 'Continuar'),
            ),
            const SizedBox(height: 12),
            Text(
              'Configuração local. Nada será enviado.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitsStep extends StatelessWidget {
  const _LimitsStep({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apoio breve, sob seu controle',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Receba sugestões simples para refletir, fazer uma prática ou buscar '
          'alguém seguro.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        const _LimitTile(
          icon: Icons.shield_outlined,
          title: 'Você mantém o controle',
          body:
              'Não é terapia nem canal de emergência. O texto livre do diário não é usado e ninguém é avisado automaticamente.',
        ),
      ],
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
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
        Text('Escolha o que usar', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Tudo começa desligado. Ative somente o que fizer sentido para você.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          key: const Key('ai-support-personalization-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Ativar sugestões personalizadas'),
          value: personalizationEnabled,
          onChanged: onPersonalizationChanged,
        ),
        const SizedBox(height: 8),
        for (final source in SupportSignalSource.values)
          SwitchListTile.adaptive(
            key: Key('ai-support-source-${source.name}'),
            contentPadding: EdgeInsets.zero,
            title: Text(source.label),
            value: sources.contains(source),
            onChanged: personalizationEnabled
                ? (enabled) => onSourceChanged(source, enabled)
                : null,
          ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Texto livre do diário indisponível nesta demonstração',
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Texto livre do diário'),
            subtitle: Text('Indisponível nesta primeira versão.'),
            enabled: false,
          ),
        ),
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  const _PreferencesStep({
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
          'Como você prefere receber apoio?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha os tipos de sugestão que combinam com você.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in SupportSuggestionCategory.values)
              FilterChip(
                key: Key('ai-support-category-${category.name}'),
                label: Text(category.label),
                selected: categories.contains(category),
                onSelected: (value) => onCategoryChanged(category, value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          key: const Key('ai-support-avoid-breathing-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Evitar conteúdo focado na respiração'),
          value: excludedContentTags.contains(
            SupportContentTag.breathingFocused,
          ),
          onChanged: onBreathingChanged,
        ),
        const Divider(height: 32),
        SwitchListTile.adaptive(
          key: const Key('ai-support-notification-simulator-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Receber lembretes'),
          subtitle: const Text('Nesta versão, aparecem somente no simulador.'),
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        if (notificationsEnabled) ...[
          ExpansionTile(
            key: const Key('ai-support-advanced-notification-settings'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: const Text('Horários e privacidade'),
            subtitle: const Text('Opcional'),
            children: [
              DropdownButtonFormField<NotificationFrequency>(
                key: const Key('ai-support-frequency-field'),
                decoration: const InputDecoration(
                  labelText: 'Frequência máxima',
                ),
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HourPicker(
                    label: 'A partir de',
                    value: startHour,
                    onChanged: onStartHourChanged,
                  ),
                  _HourPicker(
                    label: 'Até',
                    value: endHour,
                    onChanged: onEndHourChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dias', style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(7, (index) {
                  final day = index + DateTime.monday;
                  return FilterChip(
                    label: Text(_weekdayLabel(day)),
                    selected: allowedWeekdays.contains(day),
                    onSelected: (selected) => onDayChanged(day, selected),
                  );
                }),
              ),
              const SizedBox(height: 16),
              _GenericPreview(preview: lockScreenPreview),
            ],
          ),
        ],
      ],
    );
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(labelText: label),
        initialValue: value,
        items: List<DropdownMenuItem<int>>.generate(24, (hour) {
          return DropdownMenuItem(value: hour, child: Text('$hour:00'));
        }),
        onChanged: (hour) {
          if (hour != null) onChanged(hour);
        },
      ),
    );
  }
}

class _GenericPreview extends StatelessWidget {
  const _GenericPreview({required this.preview});

  final LockScreenPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genericText =
        MockSupportTemplateCatalog.genericNotifications.first.text;
    return Container(
      key: const Key('ai-support-generic-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prévia da tela bloqueada', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (preview == LockScreenPreview.generic)
            Text(genericText, style: theme.textTheme.bodyLarge)
          else
            Text(
              'Nenhuma prévia será exibida na tela bloqueada.',
              style: theme.textTheme.bodyLarge,
            ),
          const SizedBox(height: 8),
          Text(
            'Nunca mostra humor, tags, texto do diário, exercício ou contato.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

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
