import 'package:flutter/material.dart';
import 'package:iris/widgets/app_symptom_option.dart';

class AppSymptomsCard extends StatelessWidget {
  final String title;
  final List<String> symptoms;
  final List<int> selected;
  final Function(int) onTap;

  const AppSymptomsCard({
    super.key,
    required this.title,
    required this.symptoms,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 359,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF462A7E),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: List.generate(
                    (symptoms.length / 2).ceil(),
                    (index) => AppSymptomOption(
                      text: symptoms[index],
                      selected: selected.contains(index),
                      onTap: () => onTap(index),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  children: List.generate(
                    symptoms.length - (symptoms.length / 2).ceil(),
                    (index) {
                      final realIndex = index + (symptoms.length / 2).ceil();

                      return AppSymptomOption(
                        text: symptoms[realIndex],
                        selected: selected.contains(realIndex),
                        onTap: () => onTap(realIndex),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
