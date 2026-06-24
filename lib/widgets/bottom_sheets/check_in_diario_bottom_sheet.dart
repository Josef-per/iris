import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/app_align_filled_button.dart';
import 'package:iris/widgets/app_check_in_diario_card.dart';
import 'package:iris/widgets/app_check_in_header.dart';
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
  String? _errorMessage;

  static const _moodLabels = [
    'Muito feliz',
    'Bem',
    'Mais ou menos',
    'Mal',
    'Muito mal',
  ];

  Future<void> _submit() async {
    if (_isLoading) {
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
        sintomasEmocionaisHoje: mentalSymptoms.length,
        sintomasFisicosHoje: physicalSymptoms.length,
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

  void _toggleSymptom(List<int> symptoms, int index) {
    if (_isLoading) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const AppCheckInHeader(
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
