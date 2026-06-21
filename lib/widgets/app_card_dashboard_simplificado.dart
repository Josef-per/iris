import 'package:flutter/material.dart';

class AppCardDashboardSimplificado extends StatelessWidget {
  //passar os parâmetros
  final String ImageDirectory;
  final String TextIdentifier;
  final String TextName;

  const AppCardDashboardSimplificado({
    super.key,
    required this.ImageDirectory,
    required this.TextIdentifier,
    required this.TextName,
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
              Image.asset(ImageDirectory, width: 30, height: 30),
              const SizedBox(height: 10),
              Text(
                TextIdentifier,
                style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                TextName,
                style: TextStyle(color: const Color(0x99FFFFFF), fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
