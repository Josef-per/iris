import 'package:flutter/material.dart';

class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.labelText,
    required this.valueText,
  });

  final String labelText;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, color: Color(0xFF28174E)),
        ),
        const SizedBox(height: 7),
        Container(
          height: 30,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B70EA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(valueText, style: const TextStyle(color: Color(0xFF53418A))),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF28174E)),
            ],
          ),
        ),
      ],
    );
  }
}
