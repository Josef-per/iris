import 'package:flutter/material.dart';

class AppSymptomOption extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const AppSymptomOption({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: const Color(0xFF462A7E),
              size: 22,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Color(0xFF462A7E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
