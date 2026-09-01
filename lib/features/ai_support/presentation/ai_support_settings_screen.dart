import 'package:flutter/material.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/widgets/app_responsive.dart';

class AiSupportSettingsScreen extends StatelessWidget {
  const AiSupportSettingsScreen({super.key, required this.store, this.onBack});

  final MockAiSupportStore store;
  final VoidCallback? onBack;

  void _back(BuildContext context) {
    if (onBack case final callback?) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _setPersonalization(BuildContext context, bool enabled) {
    if (enabled &&
        !hasPrimaryPatientSupportSource(store.consent.grantedSources)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escolha check-ins ou temas marcados para a Íris ter um sinal atual.',
          ),
        ),
      );
      return;
    }
    final categories = store.preferences.allowedCategories.isEmpty
        ? const <SupportSuggestionCategory>{
            SupportSuggestionCategory.reflection,
            SupportSuggestionCategory.exercise,
            SupportSuggestionCategory.humanConnection,
          }
        : store.preferences.allowedCategories;
    store.configureConsent(
      store.consent.copyWith(
        personalizedSuggestionsGranted: enabled,
        grantedSources: store.consent.grantedSources,
      ),
    );
    store.configurePreferences(
      store.preferences.copyWith(
        personalizedSuggestionsEnabled: enabled,
        allowedCategories: categories,
      ),
    );
  }

  void _setSource(
    BuildContext context,
    SupportSignalSource source,
    bool enabled,
  ) {
    final sources = <SupportSignalSource>{...store.consent.grantedSources};
    enabled ? sources.add(source) : sources.remove(source);
    if (store.isPersonalizationEnabled &&
        !hasPrimaryPatientSupportSource(sources)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mantenha check-ins ou temas marcados enquanto a personalização estiver ativa.',
          ),
        ),
      );
      return;
    }
    store.configureConsent(store.consent.copyWith(grantedSources: sources));
  }

  void _setCategory(SupportSuggestionCategory category, bool enabled) {
    final categories = <SupportSuggestionCategory>{
      ...store.preferences.allowedCategories,
    };
    enabled ? categories.add(category) : categories.remove(category);
    store.configurePreferences(
      store.preferences.copyWith(allowedCategories: categories),
    );
  }

  void _setAvoidBreathing(bool enabled) {
    final tags = <SupportContentTag>{...store.preferences.excludedContentTags};
    enabled
        ? tags.add(SupportContentTag.breathingFocused)
        : tags.remove(SupportContentTag.breathingFocused);
    store.configurePreferences(
      store.preferences.copyWith(excludedContentTags: tags),
    );
  }

  Future<void> _setNotificationsEnabled(
    BuildContext context,
    bool enabled,
  ) async {
    final current = store.preferences.notifications;
    if (!enabled || store.isDemonstration) {
      store.configureNotifications(
        current.copyWith(
          enabled: enabled,
          frequency: enabled && current.frequency == NotificationFrequency.never
              ? NotificationFrequency.oncePerWeek
              : current.frequency,
        ),
      );
      return;
    }

    final permission = await store.requestNotificationPermission();
    if (!context.mounted) return;
    final allowed = permission.allowsScheduling;
    store.configureNotifications(
      current.copyWith(
        enabled: allowed,
        frequency: allowed && current.frequency == NotificationFrequency.never
            ? NotificationFrequency.oncePerWeek
            : current.frequency,
      ),
    );
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As notificações não foram ativadas. As sugestões continuam disponíveis no app.',
          ),
        ),
      );
    }
  }

  void _setFrequency(NotificationFrequency frequency) {
    store.configureNotifications(
      store.preferences.notifications.copyWith(
        enabled: frequency != NotificationFrequency.never,
        frequency: frequency,
      ),
    );
  }

  void _setPreview(LockScreenPreview preview) {
    store.configureNotifications(
      store.preferences.notifications.copyWith(lockScreenPreview: preview),
    );
  }

  void _setWindow({int? startHour, int? endHour}) {
    final current = store.preferences.notifications;
    store.configureNotifications(
      current.copyWith(
        window: current.window.copyWith(
          start: startHour == null ? null : SupportTimeOfDay(startHour),
          end: endHour == null ? null : SupportTimeOfDay(endHour),
        ),
      ),
    );
  }

  void _setDay(int day, bool enabled) {
    final current = store.preferences.notifications;
    final days = <int>{...current.window.allowedWeekdays};
    enabled ? days.add(day) : days.remove(day);
    if (days.isEmpty) return;
    store.configureNotifications(
      current.copyWith(window: current.window.copyWith(allowedWeekdays: days)),
    );
  }

  Future<void> _deletePersonalizationData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir dados das sugestões?'),
        content: const Text(
          'Isso remove preferências, temas de apoio confirmados e o histórico '
          'das sugestões. Seu diário e seus check-ins não serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await store.revokeAllConsent();
    if (!context.mounted) return;
    final message = store.lastSettingsError == null
        ? 'Dados das sugestões excluídos.'
        : 'Não foi possível concluir a exclusão. Tente novamente.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final consent = store.consent;
        final preferences = store.preferences;
        final notification = preferences.notifications;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => _back(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Suas preferências'),
          ),
          body: AppResponsive(
            maxWidth: 720,
            child: ListView(
              children: [
                Text(
                  'Apoio do seu jeito',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Você pode mudar ou desligar tudo quando quiser.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  key: const Key('ai-support-settings-personalization'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sugestões personalizadas'),
                  subtitle: const Text(
                    'Considera somente o que você permitir.',
                  ),
                  value: store.isPersonalizationEnabled,
                  onChanged: (value) => _setPersonalization(context, value),
                ),
                ExpansionTile(
                  key: const Key('ai-support-settings-data-expansion'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('O que considerar'),
                  subtitle: Text(
                    '${consent.grantedSources.length} fonte(s) escolhida(s)',
                  ),
                  children: [
                    for (final source in patientAvailableSupportSources)
                      SwitchListTile.adaptive(
                        key: Key('ai-support-settings-source-${source.name}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(source.label),
                        subtitle: Text(source.description),
                        value: consent.grantedSources.contains(source),
                        onChanged: (value) =>
                            _setSource(context, source, value),
                      ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline_rounded),
                      title: Text('Texto livre do diário não é usado'),
                    ),
                  ],
                ),
                ExpansionTile(
                  key: const Key('ai-support-settings-content-expansion'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Tipo de apoio'),
                  subtitle: const Text('Reflexão, prática ou conexão'),
                  children: [
                    for (final category in patientAvailableSupportCategories)
                      CheckboxListTile(
                        key: Key(
                          'ai-support-settings-category-${category.name}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(category.label),
                        value: preferences.allowedCategories.contains(category),
                        onChanged:
                            preferences.allowedCategories.length == 1 &&
                                preferences.allowedCategories.contains(category)
                            ? null
                            : (value) => _setCategory(category, value ?? false),
                      ),
                    SwitchListTile.adaptive(
                      key: const Key('ai-support-settings-avoid-breathing'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Evitar foco na respiração'),
                      value: preferences.excludedContentTags.contains(
                        SupportContentTag.breathingFocused,
                      ),
                      onChanged: _setAvoidBreathing,
                    ),
                    DropdownButtonFormField<int>(
                      key: const Key('ai-support-settings-duration'),
                      decoration: const InputDecoration(
                        labelText: 'Práticas de no máximo',
                      ),
                      initialValue: preferences.maximumExerciseMinutes,
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2 minutos')),
                        DropdownMenuItem(value: 3, child: Text('3 minutos')),
                        DropdownMenuItem(value: 5, child: Text('5 minutos')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          store.configurePreferences(
                            store.preferences.copyWith(
                              maximumExerciseMinutes: value,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                if (store.isPersonalizationEnabled) ...[
                  const Divider(height: 30),
                  SwitchListTile.adaptive(
                    key: const Key('ai-support-settings-notifications'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lembretes discretos'),
                    subtitle: const Text(
                      'Sem som, vibração ou detalhes pessoais.',
                    ),
                    value: notification.enabled,
                    onChanged: (value) =>
                        _setNotificationsEnabled(context, value),
                  ),
                ],
                if (notification.enabled)
                  ExpansionTile(
                    key: const Key(
                      'ai-support-settings-notification-expansion',
                    ),
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Horários e privacidade'),
                    subtitle: Text(
                      '${notification.window.start.label}–${notification.window.end.label}',
                    ),
                    children: [
                      DropdownButtonFormField<NotificationFrequency>(
                        key: const Key('ai-support-settings-frequency'),
                        decoration: const InputDecoration(
                          labelText: 'Frequência máxima',
                        ),
                        initialValue: notification.frequency,
                        items: NotificationFrequency.values
                            .where(
                              (value) => value != NotificationFrequency.never,
                            )
                            .map(
                              (frequency) => DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) _setFrequency(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _HourField(
                              label: 'A partir de',
                              value: notification.window.start.hour,
                              onChanged: (hour) => _setWindow(startHour: hour),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HourField(
                              label: 'Até',
                              value: notification.window.end.hour,
                              onChanged: (hour) => _setWindow(endHour: hour),
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
                            selected: notification.window.allowedWeekdays
                                .contains(day),
                            onSelected: (selected) => _setDay(day, selected),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LockScreenPreview>(
                        key: const Key('ai-support-settings-preview'),
                        decoration: const InputDecoration(
                          labelText: 'Na tela bloqueada',
                        ),
                        initialValue: notification.lockScreenPreview,
                        items: LockScreenPreview.values
                            .map(
                              (preview) => DropdownMenuItem(
                                value: preview,
                                child: Text(preview.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) _setPreview(value);
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                if (notification.enabled) ...[
                  const SizedBox(height: 10),
                  if (store.isPaused)
                    OutlinedButton.icon(
                      key: const Key('ai-support-resume-notifications'),
                      onPressed: store.resumeNotifications,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Retomar lembretes'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          key: const Key('ai-support-pause-7-days'),
                          onPressed: () =>
                              store.pauseFor(const Duration(days: 7)),
                          child: const Text('Pausar 7 dias'),
                        ),
                        TextButton(
                          key: const Key('ai-support-pause-30-days'),
                          onPressed: () =>
                              store.pauseFor(const Duration(days: 30)),
                          child: const Text('Pausar 30 dias'),
                        ),
                      ],
                    ),
                ],
                const Divider(height: 34),
                OutlinedButton(
                  key: const Key('ai-support-disable-personalization'),
                  onPressed: store.disablePersonalization,
                  child: const Text('Desativar personalização'),
                ),
                TextButton(
                  key: const Key('ai-support-revoke-all-data'),
                  onPressed: () => _deletePersonalizationData(context),
                  child: const Text('Excluir dados das sugestões'),
                ),
              ],
            ),
          ),
        );
      },
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
