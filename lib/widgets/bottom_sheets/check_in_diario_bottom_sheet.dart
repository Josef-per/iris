import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/emotional_diary/patient_symptoms.dart';
import 'package:iris/widgets/app_check_in_diario_card.dart';
import 'package:iris/widgets/app_mood_selector.dart';
import 'package:iris/widgets/app_symptoms_card.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInDiarioBottomSheet extends StatefulWidget {
  const CheckInDiarioBottomSheet({super.key, this.repository});

  final EmotionalDiaryDataSource? repository;

  @override
  State<CheckInDiarioBottomSheet> createState() =>
      _CheckInDiarioBottomSheetState();
}

class _CheckInDiarioBottomSheetState extends State<CheckInDiarioBottomSheet> {
  late final EmotionalDiaryDataSource _repository;

  int? selectedMood;
  int? selectedFood;
  final Set<String> mentalSymptoms = {};
  final Set<String> physicalSymptoms = {};

  bool _isLoading = false;
  bool _isLoadingTodayRecord = true;
  String? _loadErrorMessage;
  String? _errorMessage;

  static const _moodLabels = [
    'Muito feliz',
    'Bem',
    'Mais ou menos',
    'Mal',
    'Muito mal',
  ];

  static const _moodOptions = [
    _SelectorOption(
      label: 'Muito\nfeliz',
      image: 'assets/icons/MuitoFeliz_white.png',
      selectedImage: 'assets/icons/MuitoFeliz_color.png',
    ),
    _SelectorOption(
      label: 'Bem',
      image: 'assets/icons/Bem_white.png',
      selectedImage: 'assets/icons/Bem_color.png',
    ),
    _SelectorOption(
      label: 'Mais ou\nmenos',
      image: 'assets/icons/MaisOuMenos_white.png',
      selectedImage: 'assets/icons/MaisOuMenos_color.png',
    ),
    _SelectorOption(
      label: 'Mal',
      image: 'assets/icons/Mal_white.png',
      selectedImage: 'assets/icons/Mal_color.png',
    ),
    _SelectorOption(
      label: 'Muito\nmal',
      image: 'assets/icons/MuitoMal_white.png',
      selectedImage: 'assets/icons/MuitoMal_color.png',
    ),
  ];

  static const _foodOptions = [
    _SelectorOption(
      label: 'Muito\nboa',
      image: 'assets/icons/MuitoFeliz_white.png',
      selectedImage: 'assets/icons/MuitoFeliz_color.png',
    ),
    _SelectorOption(
      label: 'Boa',
      image: 'assets/icons/Bem_white.png',
      selectedImage: 'assets/icons/Bem_color.png',
    ),
    _SelectorOption(
      label: 'Mais ou\nmenos',
      image: 'assets/icons/MaisOuMenos_white.png',
      selectedImage: 'assets/icons/MaisOuMenos_color.png',
    ),
    _SelectorOption(
      label: 'Ruim',
      image: 'assets/icons/Mal_white.png',
      selectedImage: 'assets/icons/Mal_color.png',
    ),
    _SelectorOption(
      label: 'Muito\nruim',
      image: 'assets/icons/MuitoMal_white.png',
      selectedImage: 'assets/icons/MuitoMal_color.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmotionalDiaryRepository();
    _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
    setState(() {
      _isLoadingTodayRecord = true;
      _loadErrorMessage = null;
      _errorMessage = null;
    });

    try {
      final record = await _repository.getTodayRecord();
      if (!mounted) return;

      setState(() {
        selectedMood = _scoreToSelectorIndex(record?['como_sentiu']);
        selectedFood = _scoreToSelectorIndex(record?['avaliacao_alimentacao']);
        mentalSymptoms
          ..clear()
          ..addAll(
            PatientSymptoms.decode(
              record?['sintomas_emocionais_hoje'],
              PatientSymptoms.emotional,
            ),
          );
        physicalSymptoms
          ..clear()
          ..addAll(
            PatientSymptoms.decode(
              record?['sintomas_fisicos_hoje'],
              PatientSymptoms.physical,
            ),
          );
        _isLoadingTodayRecord = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = AppErrorMessages.from(error);
        _isLoadingTodayRecord = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading || _isLoadingTodayRecord || _loadErrorMessage != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (selectedMood == null || selectedFood == null) {
      setState(() {
        _errorMessage = 'Selecione como você se sentiu e avalie a alimentação.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moodIndex = selectedMood!;
    final foodIndex = selectedFood!;

    try {
      await _repository.createCheckIn(
        humor: _moodLabels[moodIndex],
        comoSentiu: _selectorIndexToScore(moodIndex),
        avaliacaoAlimentacao: _selectorIndexToScore(foodIndex),
        sintomasEmocionaisHoje: mentalSymptoms.toList(growable: false),
        sintomasFisicosHoje: physicalSymptoms.toList(growable: false),
      );
      if (!mounted) return;

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Check-in diário salvo.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _selectorIndexToScore(int index) => 5 - index;

  int? _scoreToSelectorIndex(Object? score) {
    final parsedScore = score is int
        ? score
        : int.tryParse(score?.toString() ?? '');
    if (parsedScore == null || parsedScore < 1 || parsedScore > 5) return null;
    return 5 - parsedScore;
  }

  void _selectMood(int index) {
    if (_isLoading) return;
    setState(() {
      selectedMood = index;
      _errorMessage = null;
    });
  }

  void _selectFood(int index) {
    if (_isLoading) return;
    setState(() {
      selectedFood = index;
      _errorMessage = null;
    });
  }

  void _toggleSymptom(Set<String> symptoms, String code) {
    if (_isLoading || _isLoadingTodayRecord) return;
    setState(() {
      symptoms.contains(code) ? symptoms.remove(code) : symptoms.add(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBottomSheet(
      child: _isLoadingTodayRecord
          ? const _SheetLoading()
          : _loadErrorMessage != null
          ? _CheckInLoadError(
              message: _loadErrorMessage!,
              onRetry: _loadTodayRecord,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Check-in diário',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Registre seus pensamentos, emoções e experiências do dia.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppCheckInCard(
                  title: 'Como você se sentiu hoje no geral?',
                  child: _SelectorGrid(
                    key: const Key('check-in-mood-options'),
                    options: _moodOptions,
                    selectedIndex: selectedMood,
                    onSelected: _selectMood,
                  ),
                ),
                const SizedBox(height: 16),
                AppCheckInCard(
                  title: 'Como você avaliaria sua alimentação hoje?',
                  child: _SelectorGrid(
                    key: const Key('check-in-food-options'),
                    options: _foodOptions,
                    selectedIndex: selectedFood,
                    onSelected: _selectFood,
                  ),
                ),
                const SizedBox(height: 16),
                AppSymptomsCard(
                  title: 'Quais sintomas emocionais você apresentou hoje?',
                  symptoms: PatientSymptoms.emotional
                      .map((symptom) => symptom.label)
                      .toList(growable: false),
                  selected: PatientSymptoms.selectedIndexes(
                    mentalSymptoms,
                    PatientSymptoms.emotional,
                  ),
                  onTap: (index) => _toggleSymptom(
                    mentalSymptoms,
                    PatientSymptoms.emotional[index].code,
                  ),
                ),
                const SizedBox(height: 16),
                AppSymptomsCard(
                  title: 'Quais sintomas físicos você apresentou hoje?',
                  symptoms: PatientSymptoms.physical
                      .map((symptom) => symptom.label)
                      .toList(growable: false),
                  selected: PatientSymptoms.selectedIndexes(
                    physicalSymptoms,
                    PatientSymptoms.physical,
                  ),
                  onTap: (index) => _toggleSymptom(
                    physicalSymptoms,
                    PatientSymptoms.physical[index].code,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _errorMessage!,
                      key: const Key('check-in-validation-error'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const Key('check-in-submit'),
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isLoading ? 'Salvando...' : 'Confirmar'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SelectorGrid extends StatelessWidget {
  const _SelectorGrid({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_SelectorOption> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const preferredItemWidth = 72.0;
    const minimumItemWidth = 44.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth >= 392 ? 8.0 : 4.0;
        final spacingWidth = spacing * (options.length - 1);
        final fittedItemWidth =
            (constraints.maxWidth - spacingWidth) / options.length;
        final itemWidth = fittedItemWidth.clamp(
          minimumItemWidth,
          preferredItemWidth,
        );
        final selectorRow = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < options.length; index++) ...[
              if (index > 0) SizedBox(width: spacing),
              AppMoodSelector(
                width: itemWidth,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
                image: options[index].image,
                selectedImage: options[index].selectedImage,
                text: options[index].label,
              ),
            ],
          ],
        );
        final requiredWidth =
            (minimumItemWidth * options.length) + spacingWidth;
        if (constraints.maxWidth < requiredWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: selectorRow,
          );
        }
        return Center(child: selectorRow);
      },
    );
  }
}

class _SelectorOption {
  const _SelectorOption({
    required this.label,
    required this.image,
    required this.selectedImage,
  });

  final String label;
  final String image;
  final String selectedImage;
}

class _SheetLoading extends StatelessWidget {
  const _SheetLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Carregando o check-in de hoje',
      child: const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CheckInLoadError extends StatelessWidget {
  const _CheckInLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.danger,
                size: 36,
              ),
              const SizedBox(height: 14),
              Text(
                'Não foi possível carregar o check-in',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('check-in-load-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
