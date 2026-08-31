import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/mock_notification_policy.dart';
import 'package:iris/features/ai_support/data/mock_support_templates.dart';
import 'package:iris/features/ai_support/domain/support_suggestion.dart';
import 'package:iris/features/ai_support/presentation/ai_support_onboarding_screen.dart';
import 'package:iris/features/ai_support/presentation/ai_support_settings_screen.dart';
import 'package:iris/features/ai_support/presentation/notification_preview_screen.dart';
import 'package:iris/features/ai_support/presentation/support_inbox_screen.dart';
import 'package:iris/features/ai_support/presentation/support_suggestion_screen.dart';
import 'package:iris/features/support_exercises/presentation/support_flow_screen.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Entrada autenticada de Sugestões de apoio.
///
/// O modo de demonstração mantém os cenários do protótipo. A experiência real
/// mostra somente a sugestão atual e os controles essenciais da pessoa.
class AiSupportHubScreen extends StatefulWidget {
  const AiSupportHubScreen({super.key, this.store, this.onBack});

  final MockAiSupportStore? store;
  final VoidCallback? onBack;

  @override
  State<AiSupportHubScreen> createState() => _AiSupportHubScreenState();
}

class _AiSupportHubScreenState extends State<AiSupportHubScreen> {
  late final MockAiSupportStore _store;
  late final bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? MockAiSupportStore();
    unawaited(_prepareConnectedExperience());
  }

  Future<void> _prepareConnectedExperience() async {
    await _store.waitForSettings();
    if (!mounted) return;
    setState(() {});
    if (_store.isDemonstration || !_store.isOnboarded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final openedFromNotification = _store.hasPendingNotificationOpen;
      if (openedFromNotification || _store.pendingSuggestion == null) {
        _refreshPersonalized(openWhenReady: openedFromNotification);
      }
    });
  }

  @override
  void dispose() {
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.onBack case final callback?) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiSupportSettingsScreen(store: _store),
      ),
    );
  }

  void _openSuggestion(SupportSuggestion suggestion) {
    _store.recordSuggestionOpenedInApp(suggestion);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportSuggestionScreen(
          store: _store,
          suggestion: suggestion,
          onManageData: _openSettings,
        ),
      ),
    );
  }

  Future<void> _refreshPersonalized({bool openWhenReady = true}) async {
    final suggestion = _store.isDemonstration
        ? _store.generateSuggestion()
        : await _store.generatePersonalizedSuggestion();
    if (!mounted) return;
    if (suggestion == null) {
      if (openWhenReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não há uma sugestão para agora. Você ainda pode escolher uma prática.',
            ),
          ),
        );
      }
      return;
    }
    if (openWhenReady) _openSuggestion(suggestion);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationPreviewScreen(
          store: _store,
          onOpenSuggestion: _openSuggestion,
        ),
      ),
    );
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportInboxScreen(
          store: _store,
          onOpenSuggestion: _openSuggestion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_store.settingsReady) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Apoio para você'),
        ),
        body: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Carregando suas preferências de apoio',
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (!_store.isOnboarded) {
      return AiSupportOnboardingScreen(
        store: _store,
        onBack: _back,
        onFinished: () {
          setState(() {});
          if (!_store.isDemonstration) {
            _refreshPersonalized(openWhenReady: false);
          }
        },
      );
    }
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => _SupportCenter(
        store: _store,
        onBack: _back,
        onOpenSettings: _openSettings,
        onOpenSuggestion: _openSuggestion,
        onOpenNotifications: _openNotifications,
        onOpenInbox: _openInbox,
        onGenerateSuggestion: () => _refreshPersonalized(),
      ),
    );
  }
}

class _SupportCenter extends StatelessWidget {
  const _SupportCenter({
    required this.store,
    required this.onBack,
    required this.onOpenSettings,
    required this.onOpenSuggestion,
    required this.onOpenNotifications,
    required this.onOpenInbox,
    required this.onGenerateSuggestion,
  });

  final MockAiSupportStore store;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final ValueChanged<SupportSuggestion> onOpenSuggestion;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenInbox;
  final VoidCallback onGenerateSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = store.pendingSuggestion;
    final demonstration = store.isDemonstration;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(demonstration ? 'Sugestões de apoio' : 'Apoio para você'),
        actions: [
          IconButton(
            key: const Key('ai-support-open-settings'),
            tooltip: 'Configurar sugestões',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: AppResponsive(
        maxWidth: 800,
        child: ListView(
          children: [
            Text(
              demonstration ? 'Um apoio para agora' : 'Para o seu momento',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              demonstration
                  ? 'Escolha uma sugestão breve ou outra forma de cuidado.'
                  : 'Uma sugestão breve, baseada somente no que você permitiu.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (demonstration) ...[
              _StateNotice(store: store),
              const SizedBox(height: 18),
              _ScenarioCard(
                store: store,
                onGenerateSuggestion: onGenerateSuggestion,
              ),
            ] else
              _PersonalizedNowCard(
                store: store,
                suggestion: latest,
                onGenerate: onGenerateSuggestion,
                onOpenSuggestion: onOpenSuggestion,
                onOpenSettings: onOpenSettings,
              ),
            if (demonstration && latest != null) ...[
              const SizedBox(height: 16),
              _LatestSuggestionCard(
                suggestion: latest,
                onOpen: () => onOpenSuggestion(latest),
              ),
            ],
            if (demonstration) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HubAction(
                    key: const Key('ai-support-open-inbox'),
                    icon: Icons.inbox_outlined,
                    label: 'Sugestões salvas',
                    onTap: onOpenInbox,
                  ),
                  _HubAction(
                    key: const Key('ai-support-open-settings-card'),
                    icon: Icons.tune_rounded,
                    label: 'Preferências',
                    onTap: onOpenSettings,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text('Outras opções', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HubAction(
                  icon: Icons.self_improvement_rounded,
                  label: 'Exercícios',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupportFlowScreen(
                        start: SupportFlowStart.catalog,
                      ),
                    ),
                  ),
                ),
                _HubAction(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Não estou bem',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupportFlowScreen(),
                    ),
                  ),
                ),
                _HubAction(
                  icon: Icons.emergency_share_rounded,
                  label: 'Ajuda urgente',
                  dangerous: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupportFlowScreen(
                        start: SupportFlowStart.safetyCheck,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (demonstration)
              ExpansionTile(
                key: const Key('ai-support-demo-tools'),
                tilePadding: EdgeInsets.zero,
                title: const Text('Ferramentas da demonstração'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _HubAction(
                      key: const Key('ai-support-open-notifications'),
                      icon: Icons.notifications_none_rounded,
                      label: 'Simular notificações',
                      onTap: onOpenNotifications,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma mensagem é enviada para contatos, profissionais ou serviços.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StateNotice extends StatelessWidget {
  const _StateNotice({required this.store});

  final MockAiSupportStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = store.isPaused
        ? 'Lembretes pausados.'
        : store.isPersonalizationEnabled
        ? 'Sugestões personalizadas ativas.'
        : 'Sugestões personalizadas desligadas.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            store.isPaused
                ? Icons.pause_circle_outline_rounded
                : Icons.privacy_tip_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.store,
    required this.onGenerateSuggestion,
  });

  final MockAiSupportStore store;
  final VoidCallback onGenerateSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Experimentar uma sugestão', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Escolha um exemplo para visualizar.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: const Key('ai-support-scenario-field'),
            decoration: const InputDecoration(labelText: 'Cenário'),
            initialValue: store.selectedScenario.id,
            items: store.scenarios
                .map(
                  (scenario) => DropdownMenuItem(
                    value: scenario.id,
                    child: Text(scenario.title),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) store.selectScenario(value);
            },
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('ai-support-generate'),
            onPressed: onGenerateSuggestion,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Ver sugestão'),
          ),
          if (store.lastNotificationDecision case final decision?) ...[
            const SizedBox(height: 10),
            Text(
              _notificationStatus(decision),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _notificationStatus(NotificationPolicyResult decision) {
    if (decision.canDeliver) {
      return 'Uma notificação genérica também foi exibida no simulador.';
    }
    return 'A sugestão ficou apenas dentro do app; suas preferências impediram uma notificação simulada.';
  }
}

class _PersonalizedNowCard extends StatelessWidget {
  const _PersonalizedNowCard({
    required this.store,
    required this.suggestion,
    required this.onGenerate,
    required this.onOpenSuggestion,
    required this.onOpenSettings,
  });

  final MockAiSupportStore store;
  final SupportSuggestion? suggestion;
  final VoidCallback onGenerate;
  final ValueChanged<SupportSuggestion> onOpenSuggestion;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = suggestion;
    final template = current == null
        ? null
        : MockSupportTemplateCatalog.catalog.templateById(current.templateId);
    return Container(
      key: const Key('ai-support-personalized-now'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.isRefreshing) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparando algo para você…',
              style: theme.textTheme.titleMedium,
            ),
          ] else if (!store.isPersonalizationEnabled) ...[
            Text(
              'Você escolhe se quer personalizar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ative quando quiser usar seus check-ins e temas escolhidos.',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('ai-support-enable-from-hub'),
              onPressed: onOpenSettings,
              child: const Text('Escolher preferências'),
            ),
          ] else if (current != null && template != null) ...[
            Text(template.inAppTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(template.inAppBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('ai-support-open-personalized'),
              onPressed: () => onOpenSuggestion(current),
              child: const Text('Ver sugestão'),
            ),
          ] else ...[
            Text('Quer uma sugestão breve?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('A Íris pode considerar o seu registro mais recente.'),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('ai-support-generate-personalized'),
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Ver apoio para agora'),
            ),
          ],
          if (store.isPersonalizationEnabled) ...[
            const SizedBox(height: 14),
            Text(
              'Só usa check-ins, temas que você marcou e o que funcionou antes.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestSuggestionCard extends StatelessWidget {
  const _LatestSuggestionCard({required this.suggestion, required this.onOpen});

  final SupportSuggestion suggestion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final template = MockSupportTemplateCatalog.catalog.templateById(
      suggestion.templateId,
    );
    if (template == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      key: const Key('ai-support-latest-suggestion'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uma sugestão está pronta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(template.inAppTitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('ai-support-open-latest-suggestion'),
            onPressed: onOpen,
            child: const Text('Abrir dentro do app'),
          ),
        ],
      ),
    );
  }
}

class _HubAction extends StatelessWidget {
  const _HubAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.dangerous = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dangerous;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: OutlinedButton.icon(
        style: dangerous
            ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger)
            : null,
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
