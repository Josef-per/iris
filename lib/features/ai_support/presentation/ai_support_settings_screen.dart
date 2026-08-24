import 'package:flutter/material.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/domain/ai_support_consent.dart';
import 'package:iris/features/ai_support/domain/ai_support_preferences.dart';
import 'package:iris/features/ai_support/domain/notification_preferences.dart';
import 'package:iris/features/ai_support/presentation/support_ui_labels.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Controles locais de consentimento, conteúdo e interrupção.
class AiSupportSettingsScreen extends StatelessWidget {
  const AiSupportSettingsScreen({
    super.key,
    required this.store,
    this.onBack,
  });

  final MockAiSupportStore store;
  final VoidCallback? onBack;

  void _back(BuildContext context) {
    if (onBack case final callback?) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _setPersonalization(bool enabled) {
    final consent = store.consent.copyWith(
      personalizedSuggestionsGranted: enabled,
      grantedSources: enabled
          ? store.consent.grantedSources
          : const <SupportSignalSource>{},
    );
    store.configureConsent(consent);
    store.configurePreferences(
      store.preferences.copyWith(personalizedSuggestionsEnabled: enabled),
    );
  }

  void _setSource(SupportSignalSource source, bool enabled) {
    final sources = <SupportSignalSource>{...store.consent.grantedSources};
    enabled ? sources.add(source) : sources.remove(source);
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
    store.configurePreferences(store.preferences.copyWith(excludedContentTags: tags));
  }

  void _setMaximumExerciseMinutes(int minutes) {
    store.configurePreferences(
      store.preferences.copyWith(maximumExerciseMinutes: minutes),
    );
  }

  void _setNotificationsEnabled(bool enabled) {
    final current = store.preferences.notifications;
    store.configureNotifications(
      current.copyWith(
        enabled: enabled,
        frequency: enabled && current.frequency == NotificationFrequency.never
            ? NotificationFrequency.oncePerWeek
            : current.frequency,
      ),
    );
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
            title: const Text('Configurar sugestões'),
          ),
          body: AppResponsive(
            maxWidth: 760,
            child: ListView(
              children: [
                Text('Seus controles', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Tudo nesta tela vale apenas para a demonstração local. '
                  'Nada é enviado e você pode desfazer as escolhas.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  key: const Key('ai-support-settings-personalization'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sugestões personalizadas'),
                  subtitle: Text(
                    store.isPersonalizationEnabled
                        ? 'Ativas com as fontes escolhidas abaixo.'
                        : 'Desativadas.',
                  ),
                  value: store.isPersonalizationEnabled,
                  onChanged: _setPersonalization,
                ),
                const Divider(height: 28),
                Text('Dados usados', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Revogar uma fonte elimina os sinais fictícios e sugestões '
                  'que dependiam dela.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final source in SupportSignalSource.values)
                  SwitchListTile.adaptive(
                    key: Key('ai-support-settings-source-${source.name}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(source.label),
                    subtitle: Text(source.description),
                    value: consent.grantedSources.contains(source),
                    onChanged: consent.personalizedSuggestionsGranted
                        ? (value) => _setSource(source, value)
                        : null,
                  ),
                Semantics(
                  label: 'Texto livre do diário indisponível',
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text('Texto livre do diário'),
                    subtitle: Text('Indisponível nesta primeira versão.'),
                    enabled: false,
                  ),
                ),
                const Divider(height: 32),
                Text('Tipos de sugestão', style: theme.textTheme.titleLarge),
                for (final category in SupportSuggestionCategory.values)
                  CheckboxListTile(
                    key: Key('ai-support-settings-category-${category.name}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(category.label),
                    value: preferences.allowedCategories.contains(category),
                    onChanged: (value) => _setCategory(category, value ?? false),
                  ),
                SwitchListTile.adaptive(
                  key: const Key('ai-support-settings-avoid-breathing'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evitar conteúdos focados na respiração'),
                  value: preferences.excludedContentTags.contains(
                    SupportContentTag.breathingFocused,
                  ),
                  onChanged: _setAvoidBreathing,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: const Key('ai-support-settings-duration'),
                  decoration: const InputDecoration(
                    labelText: 'Duração máxima de exercício',
                  ),
                  initialValue: preferences.maximumExerciseMinutes,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Até 2 minutos')),
                    DropdownMenuItem(value: 3, child: Text('Até 3 minutos')),
                    DropdownMenuItem(value: 5, child: Text('Até 5 minutos')),
                  ],
                  onChanged: (value) {
                    if (value != null) _setMaximumExerciseMinutes(value);
                  },
                ),
                const Divider(height: 36),
                Text('Simulador de notificações', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Não é push real. Som e vibração permanecem desligados.',
                  style: theme.textTheme.bodySmall,
                ),
                SwitchListTile.adaptive(
                  key: const Key('ai-support-settings-notifications'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exibir notificações simuladas'),
                  value: notification.enabled,
                  onChanged: _setNotificationsEnabled,
                ),
                if (notification.enabled) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NotificationFrequency>(
                    key: const Key('ai-support-settings-frequency'),
                    decoration: const InputDecoration(labelText: 'Frequência'),
                    initialValue: notification.frequency,
                    items: NotificationFrequency.values
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
                  DropdownButtonFormField<LockScreenPreview>(
                    key: const Key('ai-support-settings-preview'),
                    decoration: const InputDecoration(labelText: 'Tela bloqueada'),
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
                ],
                const SizedBox(height: 18),
                if (store.isPaused)
                  FilledButton.icon(
                    key: const Key('ai-support-resume-notifications'),
                    onPressed: store.resumeNotifications,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Retomar notificações simuladas'),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        key: const Key('ai-support-pause-7-days'),
                        onPressed: () => store.pauseFor(const Duration(days: 7)),
                        child: const Text('Pausar 7 dias'),
                      ),
                      OutlinedButton(
                        key: const Key('ai-support-pause-30-days'),
                        onPressed: () => store.pauseFor(const Duration(days: 30)),
                        child: const Text('Pausar 30 dias'),
                      ),
                    ],
                  ),
                const Divider(height: 36),
                OutlinedButton.icon(
                  key: const Key('ai-support-disable-personalization'),
                  onPressed: store.disablePersonalization,
                  icon: const Icon(Icons.pause_circle_outline_rounded),
                  label: const Text('Desativar sugestões personalizadas'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('ai-support-revoke-all-data'),
                  onPressed: store.revokeAllConsent,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Excluir sinais fictícios e consentimentos'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
