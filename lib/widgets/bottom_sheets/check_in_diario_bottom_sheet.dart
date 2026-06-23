import 'package:flutter/material.dart';
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
  //Selecionadores de modo e comida
  int? selectedMood;
  int? selectedFood;

  //Lista de sintomas
  List<int> mentalSymptoms = [];
  List<int> physicalSymptoms = [];

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

              //Card com especificações
              AppCheckInCard(
                title: 'Como você se sentiu hoje no geral?',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppMoodSelector(
                      selected: selectedMood == 0,
                      onTap: () {
                        setState(() {
                          selectedMood = 0;
                        });
                      },
                      image: 'assets/icons/MuitoFeliz_white.png',
                      selectedImage: 'assets/icons/MuitoFeliz_color.png',
                      text: 'Muito\nfeliz',
                    ),

                    AppMoodSelector(
                      selected: selectedMood == 1,
                      onTap: () {
                        setState(() {
                          selectedMood = 1;
                        });
                      },
                      image: 'assets/icons/Bem_white.png',
                      selectedImage: 'assets/icons/Bem_color.png',
                      text: 'Bem',
                    ),

                    AppMoodSelector(
                      selected: selectedMood == 2,
                      onTap: () {
                        setState(() {
                          selectedMood = 2;
                        });
                      },
                      image: 'assets/icons/MaisOuMenos_white.png',
                      selectedImage: 'assets/icons/MaisOuMenos_color.png',
                      text: 'Mais ou\nmenos',
                    ),

                    AppMoodSelector(
                      selected: selectedMood == 3,
                      onTap: () {
                        setState(() {
                          selectedMood = 3;
                        });
                      },
                      image: 'assets/icons/Mal_white.png',
                      selectedImage: 'assets/icons/Mal_color.png',
                      text: 'Mal',
                    ),

                    AppMoodSelector(
                      selected: selectedMood == 4,
                      onTap: () {
                        setState(() {
                          selectedMood = 4;
                        });
                      },
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
                      onTap: () {
                        setState(() {
                          selectedFood = 0;
                        });
                      },
                      image: 'assets/icons/MuitoFeliz_white.png',
                      selectedImage: 'assets/icons/MuitoFeliz_color.png',
                      text: 'Muito\nBoa',
                    ),

                    AppMoodSelector(
                      selected: selectedFood == 1,
                      onTap: () {
                        setState(() {
                          selectedFood = 1;
                        });
                      },
                      image: 'assets/icons/Bem_white.png',
                      selectedImage: 'assets/icons/Bem_color.png',
                      text: 'Boa',
                    ),

                    AppMoodSelector(
                      selected: selectedFood == 2,
                      onTap: () {
                        setState(() {
                          selectedFood = 2;
                        });
                      },
                      image: 'assets/icons/MaisOuMenos_white.png',
                      selectedImage: 'assets/icons/MaisOuMenos_color.png',
                      text: 'Mais ou\nmenos',
                    ),

                    AppMoodSelector(
                      selected: selectedFood == 3,
                      onTap: () {
                        setState(() {
                          selectedFood = 3;
                        });
                      },
                      image: 'assets/icons/Mal_white.png',
                      selectedImage: 'assets/icons/Mal_color.png',
                      text: 'Ruim',
                    ),

                    AppMoodSelector(
                      selected: selectedFood == 4,
                      onTap: () {
                        setState(() {
                          selectedFood = 4;
                        });
                      },
                      image: 'assets/icons/MuitoMal_white.png',
                      selectedImage: 'assets/icons/MuitoMal_color.png',
                      text: 'Muito\nRuim',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              AppSymptomsCard(
                title: 'Quais sintomas você apresentou hoje?',
                symptoms: [
                  'Insegurança',
                  'Culpa',
                  'Vômito autoinduzido',
                  'Medo',
                  'Compulsão',
                  'Ansiedade',
                ],
                selected: mentalSymptoms,
                onTap: (index) {
                  setState(() {
                    if (mentalSymptoms.contains(index)) {
                      mentalSymptoms.remove(index);
                    } else {
                      mentalSymptoms.add(index);
                    }
                  });
                },
              ),

              const SizedBox(height: 24),

              AppSymptomsCard(
                title: 'Quais sintomas físico você apresentou hoje?',
                symptoms: [
                  'Cansaço excessivo',
                  'Alteração na pressão',
                  'Problemas Digestivos',
                  'Queda de cabelo',
                  'Dificuldade de concentração',
                  'Desmaio',
                  'Fraqueza',
                  'Tontura',
                  'Náuseas',
                  'Dor de cabeça',
                ],
                selected: physicalSymptoms,
                onTap: (index) {
                  setState(() {
                    if (physicalSymptoms.contains(index)) {
                      physicalSymptoms.remove(index);
                    } else {
                      physicalSymptoms.add(index);
                    }
                  });
                },
              ),

              const SizedBox(height: 24),

              AppAlignFilledButton(
                TextButton: 'Confirmar →',
                BackgroundColor: const Color(0xFF7D6AC6),
                TextColor: const Color(0xFFFAF9F6),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
