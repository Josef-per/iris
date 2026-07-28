import 'package:flutter/material.dart';

class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.labelText,
    required this.hintText,
  });

  final String labelText;
  final String hintText;

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
          child: Text(
            hintText,
            style: const TextStyle(color: Color(0xFF877E9B)),
          ),
        ),
      ],
    );
  }
}
