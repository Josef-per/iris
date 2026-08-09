import 'package:flutter/material.dart';
import 'package:iris/widgets/app_symptom_option.dart';

class AppSymptomsCard extends StatelessWidget {
  const AppSymptomsCard({
    super.key,
    required this.title,
    required this.symptoms,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final List<String> symptoms;
  final List<int> selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(children: _buildOptions(0, symptoms.length));
              }

              final split = (symptoms.length / 2).ceil();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: _buildOptions(0, split))),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: _buildOptions(split, symptoms.length),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(int start, int end) {
    return [
      for (var index = start; index < end; index++)
        AppSymptomOption(
          text: symptoms[index],
          selected: selected.contains(index),
          onTap: () => onTap(index),
        ),
    ];
  }
}
