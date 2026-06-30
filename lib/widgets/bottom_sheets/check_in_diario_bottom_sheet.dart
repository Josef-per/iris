import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/app_align_filled_button.dart';
import 'package:iris/widgets/app_check_in_diario_card.dart';
import 'package:iris/widgets/app_headers.dart';
import 'package:iris/widgets/app_mood_selector.dart';
import 'package:iris/widgets/app_symptoms_card.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInDiarioBottomSheet extends StatefulWidget {
  const CheckInDiarioBottomSheet({super.key});

  @override
  State<CheckInDiarioBottomSheet> createState() =>
      _CheckInDiarioBottomSheetState();
}

class _CheckInDiarioBottomSheetState extends State<CheckInDiarioBottomSheet> {
  final _repository = EmotionalDiaryRepository();

  int? selectedMood;
  int? selectedFood;
  final List<int> mentalSymptoms = [];
  final List<int> physicalSymptoms = [];

  bool _isLoading = false;
  bool _isLoadingTodayRecord = true;
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
    _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
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
          ..addAll(_parseSymptomIndexes(record?['sintomas_emocionais_hoje']));
        physicalSymptoms
          ..clear()
          ..addAll(_parseSymptomIndexes(record?['sintomas_fisicos_hoje']));
        _isLoadingTodayRecord = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppErrorMessages.from(error);
        _isLoadingTodayRecord = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading || _isLoadingTodayRecord) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final moodIndex = selectedMood ?? 2;
    final foodIndex = selectedFood ?? 2;

    try {
      await _repository.createCheckIn(
        humor: _moodLabels[moodIndex],
        comoSentiu: _selectorIndexToScore(moodIndex),
        avaliacaoAlimentacao: _selectorIndexToScore(foodIndex),
        sintomasEmocionaisHoje: mentalSymptoms,
        sintomasFisicosHoje: physicalSymptoms,
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

  List<int> _parseSymptomIndexes(Object? value) {
    if (value is List) {
      return value
          .map((item) => item is int ? item : int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
    }

    return [];
  }

  void _toggleSymptom(List<int> symptoms, int index) {
    if (_isLoading || _isLoadingTodayRecord) {
      return;
    }

    setState(() {
      if (symptoms.contains(index)) {
        symptoms.remove(index);
      } else {
        symptoms.add(index);
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
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const AppHeaders(
                      TextTitle: 'Check-in diário',
                      TextSubTitle:
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
                      symptoms: const [
                        'Insegurança',
                        'Culpa',
                        'Vômito autoinduzido',
                        'Medo',
                        'Compulsão',
                        'Ansiedade',
                      ],
                      selected: mentalSymptoms,
                      onTap: (index) => _toggleSymptom(mentalSymptoms, index),
                    ),
                    const SizedBox(height: 24),
                    AppSymptomsCard(
                      title: 'Quais sintomas físicos você apresentou hoje?',
                      symptoms: const [
                        'Cansaço excessivo',
                        'Alteração na pressão',
                        'Problemas digestivos',
                        'Queda de cabelo',
                        'Dificuldade de concentração',
                        'Desmaio',
                        'Fraqueza',
                        'Tontura',
                        'Náuseas',
                        'Dor de cabeça',
                      ],
                      selected: physicalSymptoms,
                      onTap: (index) => _toggleSymptom(physicalSymptoms, index),
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
                      TextButton: _isLoading ? 'Salvando...' : 'Confirmar ->',
                      BackgroundColor: const Color(0xFF7D6AC6),
                      TextColor: const Color(0xFFFAF9F6),
                      onPressed: _submit,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
