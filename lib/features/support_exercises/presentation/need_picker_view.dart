import 'package:flutter/material.dart';
import 'package:iris/features/support_exercises/domain/recommendation_context.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

/// Seleção da necessidade, do tempo e do formato — uma pergunta por tela,
/// sem certo ou errado. Preferências sensoriais ficam em “Ajustar”.
class NeedPickerView extends StatefulWidget {
  const NeedPickerView({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
    required this.onComplete,
    required this.onBack,
    this.initialNeed,
    this.initialTime,
    this.onNeedChanged,
    this.onTimeChanged,
  });

  final AccessibilityPreferences preferences;
  final ValueChanged<AccessibilityPreferences> onPreferencesChanged;
  final ValueChanged<RecommendationContext> onComplete;

  /// Volta para o fluxo anterior quando a pessoa está na primeira pergunta.
  final VoidCallback onBack;

  /// Restaura a seleção quando a tela é recriada (ex.: após voltar da
  /// checagem de segurança).
  final SupportNeed? initialNeed;
  final SupportTime? initialTime;
  final ValueChanged<SupportNeed>? onNeedChanged;
  final ValueChanged<SupportTime>? onTimeChanged;

  @override
  State<NeedPickerView> createState() => _NeedPickerViewState();
}

enum _PickerQuestion { need, time, format }

class _NeedPickerViewState extends State<NeedPickerView> {
  _PickerQuestion _question = _PickerQuestion.need;
  late SupportNeed? _need = widget.initialNeed;
  late SupportTime? _time = widget.initialTime;

  void _goBack() {
    if (_question == _PickerQuestion.need) {
      widget.onBack();
      return;
    }
    setState(() {
      _question = switch (_question) {
        _PickerQuestion.need => _PickerQuestion.need,
        _PickerQuestion.time => _PickerQuestion.need,
        _PickerQuestion.format => _PickerQuestion.time,
      };
    });
  }

  void _selectNeed(SupportNeed need) {
    widget.onNeedChanged?.call(need);
    setState(() {
      _need = need;
      _question = _PickerQuestion.time;
    });
  }

  void _selectTime(SupportTime time) {
    widget.onTimeChanged?.call(time);
    setState(() {
      _time = time;
      _question = _PickerQuestion.format;
    });
  }

  void _selectFormat(SupportFormat format) {
    widget.onComplete(
      RecommendationContext(
        need: _need ?? SupportNeed.notSure,
        time: _time ?? SupportTime.minutes3,
        format: format,
        preferences: widget.preferences,
      ),
    );
  }

  Future<void> _openPreferences() async {
    final updated = await showModalBottomSheet<AccessibilityPreferences>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _PreferencesSheet(
        preferences: widget.preferences,
      ),
    );
    if (updated != null) widget.onPreferencesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(_subtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        ..._options,
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('need-picker-adjust'),
            onPressed: _openPreferences,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Ajustar preferências'),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('need-picker-back'),
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar'),
          ),
        ),
      ],
    );
  }

  String get _title => switch (_question) {
    _PickerQuestion.need => 'O que ajudaria mais neste momento?',
    _PickerQuestion.time => 'Quanto tempo você tem agora?',
    _PickerQuestion.format => 'Como prefere?',
  };

  String get _subtitle => switch (_question) {
    _PickerQuestion.need =>
      'Escolha o que fizer sentido. Não há resposta certa ou errada.',
    _PickerQuestion.time => 'A duração aproximada da prática.',
    _PickerQuestion.format => 'Você pode trocar a qualquer momento.',
  };

  List<Widget> get _options => switch (_question) {
    _PickerQuestion.need => [
      for (final need in SupportNeed.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            key: Key('need-${need.name}'),
            label: need.label,
            subtitle: need.description,
            selected: _need == need,
            onTap: () => _selectNeed(need),
          ),
        ),
    ],
    _PickerQuestion.time => [
      for (final time in SupportTime.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            key: Key('time-${time.name}'),
            label: time.label,
            selected: _time == time,
            onTap: () => _selectTime(time),
          ),
        ),
    ],
    _PickerQuestion.format => [
      for (final format in SupportFormat.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            key: Key('format-${format.name}'),
            label: format.label,
            subtitle: _formatDescription(format),
            selected: false,
            onTap: () => _selectFormat(format),
          ),
        ),
    ],
  };

  static String _formatDescription(SupportFormat format) =>
      switch (format) {
        SupportFormat.interactive => 'Cartões e pequenas escolhas na tela.',
        SupportFormat.audio => 'Instruções narradas, sem precisar ler.',
        SupportFormat.video => 'Vídeo curto com transcrição.',
      };
}

class _PreferencesSheet extends StatefulWidget {
  const _PreferencesSheet({required this.preferences});

  final AccessibilityPreferences preferences;

  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  late AccessibilityPreferences _preferences = widget.preferences;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajustar preferências',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'As escolhas valem só para esta sessão e não são salvas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              key: const Key('pref-no-animation'),
              title: const Text('Sem animação'),
              value: _preferences.noAnimation,
              onChanged: (value) => setState(
                () => _preferences = _preferences.copyWith(noAnimation: value),
              ),
            ),
            SwitchListTile(
              key: const Key('pref-no-sound'),
              title: const Text('Sem som'),
              value: _preferences.noSound,
              onChanged: (value) => setState(
                () => _preferences = _preferences.copyWith(noSound: value),
              ),
            ),
            SwitchListTile(
              key: const Key('pref-avoid-breathing'),
              title: const Text('Evitar exercícios focados na respiração'),
              value: _preferences.avoidBreathing,
              onChanged: (value) => setState(
                () => _preferences = _preferences.copyWith(
                  avoidBreathing: value,
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('pref-larger-text'),
              title: const Text('Usar texto maior'),
              value: _preferences.largerText,
              onChanged: (value) => setState(
                () => _preferences = _preferences.copyWith(largerText: value),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('pref-save'),
              onPressed: () => Navigator.pop(context, _preferences),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}