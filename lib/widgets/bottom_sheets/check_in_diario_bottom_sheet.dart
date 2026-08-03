import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/emotional_diary/patient_symptoms.dart';
import 'package:iris/widgets/app_align_filled_button.dart';
import 'package:iris/widgets/app_check_in_diario_card.dart';
import 'package:iris/widgets/app_headers.dart';
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

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

      setState(() {
        _loadErrorMessage = AppErrorMessages.from(error);
        _isLoadingTodayRecord = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading || _isLoadingTodayRecord) {
      return;
    }

    if (_loadErrorMessage != null) {
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

      if (!mounted) {
        return;
      }

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Check-in diário salvo.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppErrorMessages.from(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _selectorIndexToScore(int index) {
    return 5 - index;
  }

  int? _scoreToSelectorIndex(Object? score) {
    final parsedScore = score is int
        ? score
        : int.tryParse(score?.toString() ?? '');

    if (parsedScore == null) {
      return null;
    }

    return (5 - parsedScore).clamp(0, 4).toInt();
  }

  void _toggleSymptom(Set<String> symptoms, String code) {
    if (_isLoading || _isLoadingTodayRecord) {
      return;
    }

    setState(() {
      if (symptoms.contains(code)) {
        symptoms.remove(code);
      } else {
        symptoms.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoadingTodayRecord
              ? const Center(child: CircularProgressIndicator())
              : _loadErrorMessage != null
              ? _CheckInLoadError(
                  message: _loadErrorMessage!,
                  onRetry: _loadTodayRecord,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const AppHeaders(
                      textTitle: 'Check-in diário',
                      textSubTitle:
                          'Registre seus pensamentos, emoções e experiências do dia',
                    ),
                    const SizedBox(height: 19),
                    AppCheckInCard(
                      title: 'Como você se sentiu hoje no geral?',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppMoodSelector(
                            selected: selectedMood == 0,
                            onTap: () => setState(() => selectedMood = 0),
                            image: 'assets/icons/MuitoFeliz_white.png',
                            selectedImage: 'assets/icons/MuitoFeliz_color.png',
                            text: 'Muito\nfeliz',
                          ),
                          AppMoodSelector(
                            selected: selectedMood == 1,
                            onTap: () => setState(() => selectedMood = 1),
                            image: 'assets/icons/Bem_white.png',
                            selectedImage: 'assets/icons/Bem_color.png',
                            text: 'Bem',
                          ),
                          AppMoodSelector(
                            selected: selectedMood == 2,
                            onTap: () => setState(() => selectedMood = 2),
                            image: 'assets/icons/MaisOuMenos_white.png',
                            selectedImage: 'assets/icons/MaisOuMenos_color.png',
                            text: 'Mais ou\nmenos',
                          ),
                          AppMoodSelector(
                            selected: selectedMood == 3,
                            onTap: () => setState(() => selectedMood = 3),
                            image: 'assets/icons/Mal_white.png',
                            selectedImage: 'assets/icons/Mal_color.png',
                            text: 'Mal',
                          ),
                          AppMoodSelector(
                            selected: selectedMood == 4,
                            onTap: () => setState(() => selectedMood = 4),
                            image: 'assets/icons/MuitoMal_white.png',
                            selectedImage: 'assets/icons/MuitoMal_color.png',
                            text: 'Muito\nmal',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppCheckInCard(
                      title: 'Como você avaliaria sua alimentação hoje?',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppMoodSelector(
                            selected: selectedFood == 0,
                            onTap: () => setState(() => selectedFood = 0),
                            image: 'assets/icons/MuitoFeliz_white.png',
                            selectedImage: 'assets/icons/MuitoFeliz_color.png',
                            text: 'Muito\nboa',
                          ),
                          AppMoodSelector(
                            selected: selectedFood == 1,
                            onTap: () => setState(() => selectedFood = 1),
                            image: 'assets/icons/Bem_white.png',
                            selectedImage: 'assets/icons/Bem_color.png',
                            text: 'Boa',
                          ),
                          AppMoodSelector(
                            selected: selectedFood == 2,
                            onTap: () => setState(() => selectedFood = 2),
                            image: 'assets/icons/MaisOuMenos_white.png',
                            selectedImage: 'assets/icons/MaisOuMenos_color.png',
                            text: 'Mais ou\nmenos',
                          ),
                          AppMoodSelector(
                            selected: selectedFood == 3,
                            onTap: () => setState(() => selectedFood = 3),
                            image: 'assets/icons/Mal_white.png',
                            selectedImage: 'assets/icons/Mal_color.png',
                            text: 'Ruim',
                          ),
                          AppMoodSelector(
                            selected: selectedFood == 4,
                            onTap: () => setState(() => selectedFood = 4),
                            image: 'assets/icons/MuitoMal_white.png',
                            selectedImage: 'assets/icons/MuitoMal_color.png',
                            text: 'Muito\nruim',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppSymptomsCard(
                      title: 'Quais sintomas você apresentou hoje?',
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
                    const SizedBox(height: 24),
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
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFFD6D6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppAlignFilledButton(
                      textButton: _isLoading ? 'Salvando...' : 'Confirmar ->',
                      backgroundColor: const Color(0xFF7D6AC6),
                      textColor: const Color(0xFFFAF9F6),
                      onPressed: _submit,
                    ),
                  ],
                ),
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppHeaders(
          textTitle: 'Check-in diário',
          textSubTitle: 'Não foi possível carregar o registro de hoje.',
        ),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFD6D6)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('check-in-load-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}
