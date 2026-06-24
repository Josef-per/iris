import 'package:flutter/material.dart';

class AppCardDashboardSimplificado extends StatelessWidget {
  //passar os parâmetros
  final String imageDirectory;
  final String textIdentifier;
  final String textName;

  const AppCardDashboardSimplificado({
    super.key,
    required this.imageDirectory,
    required this.textIdentifier,
    required this.textName,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0x997D6AC6),

      child: SizedBox(
        width: 90,
        height: 110,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Image.asset(imageDirectory, width: 30, height: 30),
              const SizedBox(height: 10),
              Text(
                textIdentifier,
                style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                textName,
                style: TextStyle(color: const Color(0x99FFFFFF), fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
