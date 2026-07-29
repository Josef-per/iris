import 'package:flutter/material.dart';
import 'package:iris/widgets/app_time_picker.dart';

class AppCheckInImageTimePicker extends StatelessWidget {
  const AppCheckInImageTimePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/Refeicao_exemplo.png',
          width: double.infinity,
          height: 350,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horário da refeição',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF28174E),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 48, child: Column(children: [AppTimePicker()])),
            ],
          ),
        ),
      ],
    );
  }
}
